require "rails_helper"

# The framework's axiom -- inference must not become evidence -- applies to
# this system's own output. A human may overturn a machine classification, but
# the machine's judgement is retained rather than overwritten.
RSpec.describe Claim do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "…") }
  let(:claim)     { document.claims.create!(position: 1, text: "Therefore God exists.") }

  def category(key, position)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                          position: position, definition: "…", confidence_source: "…")
  end

  it "has no category before anything has classified it" do
    expect(claim.category).to be_nil
  end

  it "uses the machine classification when it is the only one" do
    ontological = category("ontological", 1)
    claim.classifications.create!(claim_category: ontological, origin: "model", confidence: 0.9)

    expect(claim.category).to eq ontological
  end

  it "prefers a human classification over a machine one" do
    ontological = category("ontological", 1)
    interpretive = category("interpretive", 2)
    claim.classifications.create!(claim_category: ontological, origin: "model", confidence: 0.9)
    claim.classifications.create!(claim_category: interpretive, origin: "human", classifier: "jeff")

    expect(claim.category).to eq interpretive
  end

  it "retains the machine judgement after a human overturns it" do
    ontological = category("ontological", 1)
    interpretive = category("interpretive", 2)
    claim.classifications.create!(claim_category: ontological, origin: "model", confidence: 0.9)
    claim.classifications.create!(claim_category: interpretive, origin: "human", classifier: "jeff")

    machine = claim.classifications.by_model.sole
    expect(machine.claim_category).to eq ontological
    expect(machine).to be_inferred
  end

  it "rejects a confidence outside 0..1" do
    ontological = category("ontological", 1)
    classification = claim.classifications.build(claim_category: ontological, origin: "model", confidence: 1.5)

    expect(classification).not_to be_valid
  end
end
