require "rails_helper"

# The premise a step was judged under, read back rather than inferred (ADR 24).
#
# Four designs across two scopes could not tell a real argumentative step from a
# pair that was never an argument, so this asks a question the record can already
# answer instead: under what commitment was this judged, and what would another
# tradition have charged for the same move?
RSpec.describe StepPremises do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "One. Two.") }
  let(:reader) { Referent.create!(key: "reader", name: "Reader", primitive: "system") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def step(from_key, to_key)
    base = document.claims.count
    a = document.claims.create!(position: base + 1, text: "one")
    b = document.claims.create!(position: base + 2, text: "two")
    a.classify!(category(from_key), asserter: reader)
    b.classify!(category(to_key), asserter: reader)
    Transition.create!(source: a, target: b)
  end

  describe "the premise behind a verdict" do
    it "names the declared weight and the reason given for it" do
      reading = described_class.for(step("ontological", "normative"), framework: framework)

      expect(reading.crossing).to eq("ontological → normative")
      expect(reading.weight).to eq(2)
      expect(reading.rationale).to include("Hume")
    end

    # The premise exists before the verdict does — it is declared in advance,
    # which is what makes the counterfactual readable without buying a reading.
    it "reads the crossing from the claims, not from a ruling" do
      reading = described_class.for(step("observation", "ontological"), framework: framework)

      expect(reading.crossing).to eq("observation → ontological")
      # The absence of a ruling, said out loud rather than filled in.
      expect(reading.verdict).to eq("undetermined")
      expect(reading).not_to be_judged
      expect(reading).not_to be_premised
    end

    it "says the charge settled it when an unearned verdict rests on a cost" do
      transition = step("ontological", "normative")
      GovernanceSentinel.review!(transition, framework: framework)

      reading = described_class.for(transition, framework: framework)

      expect(reading.verdict).to eq("unearned")
      expect(reading.decisive).to be(true)
    end

    it "says the absence of a charge settled it when a lateral move was earned" do
      transition = step("ontological", "interpretive")
      GovernanceSentinel.review!(transition, framework: framework)

      reading = described_class.for(transition, framework: framework)

      expect(reading.verdict).to eq("earned")
      expect(reading.weight).to eq(0)
      expect(reading.decisive).to be(true)
    end

    it "has no crossing and no premise when either claim is unclassified" do
      a = document.claims.create!(position: 1, text: "one")
      b = document.claims.create!(position: 2, text: "two")
      a.classify!(category("objective"), asserter: reader)

      reading = described_class.for(Transition.create!(source: a, target: b), framework: framework)

      expect(reading.crossing).to be_nil
      expect(reading).not_to be_premised
    end
  end

  describe "what every tradition says about the same move" do
    let(:lewisian) do
      other = Framework.create!(key: "lewisian-1.0", name: "Lewisian", version: "1.0", current: false)
      framework.claim_categories.each do |c|
        ClaimCategory.create!(framework: other, key: c.key, name: c.name, position: c.position,
                              justification_rank: c.justification_rank, definition: c.definition,
                              confidence_source: c.confidence_source)
      end
      mine = ClaimCategory.where(framework: other).index_by(&:key)
      CategoryPromotion.where(framework: framework).includes(:from_category, :to_category).each do |p|
        pair = [ p.from_category.key, p.to_category.key ]
        weight = pair.sort == %w[normative ontological] ? 0 : p.weight
        CategoryPromotion.create!(framework: other, from_category: mine[pair.first],
                                  to_category: mine[pair.last], weight: weight)
      end
      other
    end

    it "reads a framework's position whether or not it has ruled" do
      transition = step("ontological", "normative")
      GovernanceSentinel.review!(transition, framework: framework)
      lewisian # declared, but never asked

      spread = described_class.spread(transition, frameworks: [ framework, lewisian ])

      expect(spread.weights[framework]).to eq(2)
      expect(spread.weights[lewisian]).to eq(0)
      expect(spread.positions[framework].ruled).to be(true)
      expect(spread.positions[lewisian].ruled).to be(false)
      expect(spread).to be_differ
    end

    it "names the traditions that would let the move pass for nothing" do
      spread = described_class.spread(step("ontological", "normative"),
                                      frameworks: [ framework, lewisian ])

      expect(spread.permissive).to eq([ lewisian ])
    end

    it "reports a framework that never declared the crossing as silent, not free" do
      quiet = Framework.create!(key: "quiet-1.0", name: "Quiet", version: "1.0", current: false)
      framework.claim_categories.each do |c|
        ClaimCategory.create!(framework: quiet, key: c.key, name: c.name, position: c.position,
                              justification_rank: c.justification_rank, definition: c.definition,
                              confidence_source: c.confidence_source)
      end

      spread = described_class.spread(step("ontological", "normative"), frameworks: [ quiet ])

      expect(spread.positions[quiet]).to be_silent
      expect(spread.permissive).to be_empty
    end
  end

  # The caveat is part of the output, so no report can print the commitment a
  # step was judged under as the commitment its author held.
  describe "what it refuses to claim" do
    it "carries the caveat on every reading" do
      expect(described_class.for(step("ontological", "normative"), framework: framework).caveat)
        .to eq(StepPremises::CAVEAT)
      expect(described_class.spread(step("objective", "normative")).caveat)
        .to include("not the one its author held")
    end
  end
end
