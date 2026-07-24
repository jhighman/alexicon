require "rails_helper"

RSpec.describe Transition do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "…") }

  def category(key, position)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                          position: position, definition: "…", confidence_source: "…")
  end

  def claim(position, text)
    document.claims.create!(position: position, text: text)
  end

  describe "#category_change?" do
    it "is true when the claims carry different categories" do
      observation = category("observation", 1)
      ontological = category("ontological", 2)
      a, b = claim(1, "I experienced peace."), claim(2, "Therefore God exists.")
      a.classifications.create!(claim_category: observation, origin: "model")
      b.classifications.create!(claim_category: ontological, origin: "model")

      transition = described_class.create!(document: document, from_claim: a, to_claim: b)

      expect(transition.category_change?).to be true
    end

    it "is false when both claims share a category" do
      observation = category("observation", 1)
      a, b = claim(1, "I saw a wall."), claim(2, "I saw it collapse.")
      a.classifications.create!(claim_category: observation, origin: "model")
      b.classifications.create!(claim_category: observation, origin: "model")

      transition = described_class.create!(document: document, from_claim: a, to_claim: b)

      expect(transition.category_change?).to be false
    end

    it "is false when either claim is unclassified, rather than guessing" do
      observation = category("observation", 1)
      a, b = claim(1, "I experienced peace."), claim(2, "Therefore God exists.")
      a.classifications.create!(claim_category: observation, origin: "model")

      transition = described_class.create!(document: document, from_claim: a, to_claim: b)

      expect(transition.category_change?).to be false
    end
  end

  describe "verdict" do
    it "defaults to undetermined so that 'not yet known' is representable" do
      a, b = claim(1, "one"), claim(2, "two")
      transition = described_class.create!(document: document, from_claim: a, to_claim: b)

      expect(transition.verdict).to eq "undetermined"
      expect(transition.score).to be_nil
    end

    it "rejects a verdict outside the permitted set" do
      a, b = claim(1, "one"), claim(2, "two")
      transition = described_class.new(document: document, from_claim: a, to_claim: b, verdict: "false")

      expect(transition).not_to be_valid
    end
  end

  it "refuses a transition from a claim to itself" do
    a = claim(1, "one")
    transition = described_class.new(document: document, from_claim: a, to_claim: a)

    expect(transition).not_to be_valid
    expect(transition.errors[:to_claim]).to be_present
  end
end
