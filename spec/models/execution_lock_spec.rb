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
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end

  let(:classifier) do
    Referent.create!(name: "Claim Classifier", subject: "System", role: "Classifier",
                     primitive: "system")
  end

  def lock!
    mention = claim.mentions.create!(text: "Pugsley")
    IdentitySentinel.verify!(mention)
  end

  # Build-then-save so the validation failure is inspectable.
  def classify(asserter)
    assertion = claim.assertions.build(asserter: asserter, act: "classify", object: category)
    assertion.save
    assertion
  end

  it "permits classification when nothing is blocking" do
    expect(classify(classifier)).to be_persisted
  end

  it "refuses to classify a claim while identity is unresolved" do
    lock!

    classification = classify(classifier)

    expect(classification).not_to be_persisted
    expect(classification.errors[:base].join).to include "execution is locked"
  end

  it "refuses a human classification too — the lock is not about who is asking" do
    lock!

    classification = classify(reviewer)

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
    expect(classify(classifier)).not_to be_persisted

    document.open_stops.each { it.dispose!(as: "accepted", by: reviewer) }

    expect(classify(classifier)).to be_persisted
  end
end
