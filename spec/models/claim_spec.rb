require "rails_helper"

# The framework's axiom -- inference must not become evidence -- applies to
# this system's own output. A person may overturn a system's classification,
# but the system's judgement is retained rather than overwritten.
RSpec.describe Claim do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "…") }
  let(:claim)     { document.claims.create!(position: 1, text: "Therefore God exists.") }
  let(:classifier) do
    Referent.create!(name: "Claim Classifier", subject: "System", role: "Classifier",
                     primitive: "system")
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end

  def category(key, position)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                          position: position, definition: "…", confidence_source: "…")
  end

  it "has no category before anything has classified it" do
    expect(claim.category).to be_nil
  end

  it "uses the system classification when it is the only one" do
    ontological = category("ontological", 1)
    claim.classify!(ontological, asserter: classifier, confidence: 0.9)

    expect(claim.category).to eq ontological
  end

  it "prefers a person's classification over a system's" do
    ontological = category("ontological", 1)
    interpretive = category("interpretive", 2)
    claim.classify!(ontological, asserter: classifier, confidence: 0.9)
    claim.classify!(interpretive, asserter: reviewer)

    expect(claim.category).to eq interpretive
  end

  it "retains the system judgement after a person overturns it" do
    ontological = category("ontological", 1)
    interpretive = category("interpretive", 2)
    claim.classify!(ontological, asserter: classifier, confidence: 0.9)
    claim.classify!(interpretive, asserter: reviewer)

    machine = claim.classifications.reject(&:human?).sole
    expect(machine.object).to eq ontological
    expect(machine).to be_inferred
  end

  # Origin is not stored. It is a fact about who asserted.
  it "derives inferred-ness from the asserter rather than a column" do
    ontological = category("ontological", 1)
    by_system = claim.classify!(ontological, asserter: classifier)
    by_person = claim.classify!(ontological, asserter: reviewer)

    expect(by_system).to be_inferred
    expect(by_person).to be_human
    expect(Assertion.column_names).not_to include("origin", "current")
  end

  it "rejects a confidence outside 0..1" do
    ontological = category("ontological", 1)
    classification = claim.assertions.build(asserter: classifier, act: "classify",
                                            object: ontological,
                                            claim: { "confidence" => 1.5 })

    expect(classification).not_to be_valid
  end

  it "stops counting a superseded classification as current" do
    ontological = category("ontological", 1)
    interpretive = category("interpretive", 2)
    first = claim.classify!(ontological, asserter: classifier)
    claim.classify!(interpretive, asserter: classifier, supersedes: first)

    expect(claim.category).to eq interpretive
    expect(claim.classifications).not_to include(first)
    expect(claim.assertions.count).to eq 2
  end
end
