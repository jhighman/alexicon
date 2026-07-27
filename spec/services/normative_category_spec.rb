require "rails_helper"

# The fifth category.
#
# The flow stages end in ACTION and there was nowhere to put a claim about what
# should be done, so prescription landed in interpretive or ontological for want
# of anywhere better. The framework policed meaning becoming existence and left
# description becoming prescription entirely alone — the same species of
# crossing, and arguably the more consequential one.
RSpec.describe "the normative category" do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:document) { Document.create!(body: "…") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    c.classify!(category(kind), asserter: person, confidence: 1.0)
    c
  end

  def judge(from_kind, to_kind)
    GovernanceSentinel.review!(Transition.create!(source: claim("From.", from_kind),
                                                 target: claim("To.", to_kind)))
  end

  def weight(from, to) = CategoryPromotion.weight_for(from: category(from), to: category(to))

  it "exists, and sits at the same rank as ontological" do
    normative = category("normative")

    expect(normative.definition).to eq "Claim about what ought to be done, or what is of value."
    expect(normative.justification_rank).to eq category("ontological").justification_rank
  end

  # An unweighted pair reports unjudged rather than permitted, so a category
  # added without weights would quietly stop the audit seeing anything.
  it "leaves no ordered pair unweighted" do
    pairs = framework.claim_categories.to_a.permutation(2)
    unweighted = pairs.reject { |from, to| CategoryPromotion.weight_for(from: from, to: to) }

    expect(unweighted).to be_empty
    expect(pairs.size).to eq 20
  end

  describe "the crossing it exists to police" do
    it "flags description becoming prescription" do
      expect(judge("observation", "normative").verdict).to eq "unearned"
      expect(judge("objective", "normative").verdict).to eq "unearned"
    end

    it "flags meaning becoming obligation, at the same cost as meaning becoming existence" do
      expect(judge("interpretive", "normative").verdict).to eq "unearned"
      expect(weight("interpretive", "normative")).to eq weight("interpretive", "ontological")
    end

    it "flags what exists settling what should be done" do
      expect(judge("ontological", "normative").verdict).to eq "unearned"
    end
  end

  # Everywhere else in the table the ascent costs and the descent is free,
  # because coming down means retreating to firmer ground. Nothing about an
  # ought is firmer ground for an is, so this pair breaks that shape on purpose.
  describe "is and ought are symmetric, unlike promotion and retreat" do
    it "costs the same in both directions" do
      expect(weight("ontological", "normative")).to eq weight("normative", "ontological")
      expect(judge("normative", "ontological").verdict).to eq "unearned"
    end

    it "is not the shape the older pairs take" do
      expect(weight("interpretive", "ontological")).to be > 0
      expect(weight("ontological", "interpretive")).to eq 0
    end

    # They share a rank and are still not lateral. This is why the audit reads
    # the ordered pair rather than the difference in ranks.
    it "is not treated as lateral despite the equal rank" do
      expect(category("normative").justification_rank).to eq category("ontological").justification_rank
      expect(weight("normative", "ontological")).to be > 0
      expect(weight("objective", "observation")).to eq 0
    end
  end

  describe "descending out of it" do
    it "demands nothing, like every other retreat to firmer ground" do
      %w[objective observation interpretive].each do |kind|
        expect(weight("normative", kind)).to eq 0
        expect(judge("normative", kind).verdict).not_to eq "unearned"
      end
    end
  end

  # The classifier builds both its prompt and its response schema from the
  # framework, so a category added to the record reaches the model without any
  # code change. That is the property being checked, not the wording.
  describe "reaching the classifier" do
    let(:classifier) { ClaimClassifier.new([ document.claims.create!(position: 1, text: "One ought to.") ]) }

    it "offers the category to the model as an answer it may give" do
      enum = classifier.send(:schema)
                       .dig(:properties, :classifications, :items, :properties, :category, :enum)

      expect(enum).to include "normative"
    end

    it "tells the model what the category means" do
      expect(classifier.send(:system_prompt)).to include "what ought to be done"
    end
  end
end
