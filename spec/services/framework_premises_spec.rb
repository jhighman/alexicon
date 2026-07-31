require "rails_helper"

# The value content of a judgement, read back rather than inferred (ADR 24).
#
# The invariant under test is that nothing here guesses. Every figure comes from
# a declared weight, and where a framework has said nothing the absence is
# reported as an absence rather than as zero.
RSpec.describe FrameworkPremises do
  before { seed_quietly }

  let(:framework) { Framework.current! }

  # A rival speaking the same vocabulary, with named crossings repriced. Matched
  # by key, which is what lets a claim classified under one framework be judged
  # under another. Built here rather than looked up, so the spec does not depend
  # on what happens to be in a development database.
  def rival(key, overrides = {})
    other = Framework.create!(key: key, name: key.titleize, version: "1.0", current: false)
    framework.claim_categories.each do |category|
      ClaimCategory.create!(framework: other, key: category.key, name: category.name,
                            position: category.position, justification_rank: category.justification_rank,
                            definition: category.definition, confidence_source: category.confidence_source)
    end
    mine = ClaimCategory.where(framework: other).index_by(&:key)

    CategoryPromotion.where(framework: framework).includes(:from_category, :to_category).each do |promotion|
      pair = [ promotion.from_category.key, promotion.to_category.key ]
      CategoryPromotion.create!(framework: other, from_category: mine[pair.first],
                                to_category: mine[pair.last],
                                weight: overrides.fetch(pair, promotion.weight))
    end
    other
  end

  describe "what a framework charges" do
    it "reads the declared weight and the reason given for it" do
      charge = described_class.for(framework).charge("ontological", "normative")

      expect(charge.weight).to eq(2)
      expect(charge.rationale).to include("Hume")
      expect(charge.crossing).to eq("ontological → normative")
    end

    it "orders the commitments heaviest first" do
      weights = described_class.for(framework).charges.map(&:weight)

      expect(weights).to eq(weights.sort.reverse)
    end

    it "separates what costs from what is free" do
      premises = described_class.for(framework)

      expect(premises.costly).to all(satisfy { |c| c.weight.positive? })
      expect(premises.costly.map(&:crossing)).not_to include("normative → objective")
    end

    # "No rule for this pair" and "this pair costs nothing" are different, and
    # collapsing them would licence unweighted moves.
    it "reports a crossing never declared as silent, not as free" do
      quiet = Framework.create!(key: "quiet-1.0", name: "Quiet", version: "1.0", current: false)
      framework.claim_categories.each do |category|
        ClaimCategory.create!(framework: quiet, key: category.key, name: category.name,
                              position: category.position, justification_rank: category.justification_rank,
                              definition: category.definition, confidence_source: category.confidence_source)
      end

      premises = described_class.for(quiet)

      expect(premises.charges).to be_empty
      expect(premises.silent).to include(%w[ontological normative])
    end
  end

  describe "comparing two traditions" do
    # Holds that a claim about what ought to be is a claim about what is, so
    # Hume's crossing costs nothing in either direction. Everything else
    # identical, which is what makes the comparison a measurement.
    let(:lewisian) do
      rival("lewisian-1.0", { %w[ontological normative] => 0, %w[normative ontological] => 0 })
    end

    # Reproduces BASELINE-v3 §7 as a routine rather than a one-off.
    it "finds the crossings they disagree on and no others" do
      comparison = described_class.compare(framework, lewisian)

      expect(comparison.divergences.map(&:crossing))
        .to match_array([ "ontological → normative", "normative → ontological" ])
    end

    it "reads one as stricter when it charges at least as much everywhere" do
      comparison = described_class.compare(framework, lewisian)

      expect(comparison.relation).to eq(:left_stricter)
      expect(comparison.to_s).to include("stricter")
    end

    it "reads them as equivalent when nothing differs" do
      comparison = described_class.compare(framework, framework)

      expect(comparison).not_to be_differ
      expect(comparison.relation).to eq(:equivalent)
    end

    # A vector of charges has no single dimension, so two frameworks that each
    # charge more somewhere are incomparable — reported, not resolved into a
    # strictness score.
    it "refuses to order two that each charge more than the other somewhere" do
      contrary = rival("contrary-1.0",
                       { %w[ontological normative] => 0, %w[interpretive objective] => 3 })

      comparison = described_class.compare(framework, contrary)

      expect(comparison.relation).to eq(:incomparable)
      expect(comparison).not_to be_comparable
      expect(comparison.to_s).to include("incomparable")
    end
  end
end
