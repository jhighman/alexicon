require "rails_helper"

# Identity verification precedes reasoning (Layers 0-12, before the deeper
# layers). The lock is enforced, not advisory -- a query downstream code may
# decline to ask is not a lock.
RSpec.describe "execution lock" do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "Pugsley left.") }
  let(:claim)     { document.claims.create!(position: 1, text: "Pugsley left.") }
  let(:category) do
    ClaimCategory.create!(framework: framework, key: "observation", name: "Observation",
                          position: 1, definition: "…", confidence_source: "…")
  end

  def lock!
    mention = claim.mentions.create!(text: "Pugsley")
    IdentitySentinel.verify!(mention)
  end

  it "permits classification when nothing is blocking" do
    expect(claim.classifications.create(claim_category: category, origin: "model")).to be_persisted
  end

  it "refuses to classify a claim while identity is unresolved" do
    lock!

    classification = claim.classifications.create(claim_category: category, origin: "model")

    expect(classification).not_to be_persisted
    expect(classification.errors[:base].join).to include "execution is locked"
  end

  it "refuses a human classification too — the lock is not about who is asking" do
    lock!

    classification = claim.classifications.create(claim_category: category, origin: "human",
                                                  classifier: "jeff")

    expect(classification).not_to be_persisted
  end

  it "raises when a reasoning layer asks to proceed" do
    lock!

    expect { document.require_executable! }
      .to raise_error(Document::ExecutionLocked, /Pugsley/)
  end

  it "is silent when execution may proceed" do
    expect { document.require_executable! }.not_to raise_error
  end

  # Agency is preserved: a person may resolve the ambiguity and proceed. What
  # they may not do is reason past it silently.
  it "lifts once a person disposes of the flag" do
    lock!
    expect(claim.classifications.create(claim_category: category, origin: "model")).not_to be_persisted

    document.flags.open.stopping.each { it.dispose!(as: "accepted", by: "jeff") }

    expect(claim.classifications.create(claim_category: category, origin: "model")).to be_persisted
  end
end
