require "rails_helper"

# Identity verification precedes reasoning ABOUT an entity. The lock is
# enforced, not advisory -- a query downstream code may decline to ask is not a
# lock -- but it guards predication, not description.
#
# The distinction is load-bearing. Classifying asks what KIND of statement
# something is, and that does not depend on who a name inside it refers to.
# Gating classification on resolution made ordinary prose unreadable: a single
# essay citing unfamiliar authors produced 204 blocking questions and could not
# be typed at all. Judging that a step between claims was earned is a different
# act, and that one does reason about what the names refer to.
RSpec.describe "execution lock" do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "Pugsley left. So he is gone.") }
  let(:claim)     { document.claims.create!(position: 1, text: "Pugsley left.") }
  let(:conclusion) { document.claims.create!(position: 2, text: "So he is gone.") }
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

  # Build-then-save so a validation failure is inspectable.
  def classify(asserter)
    assertion = claim.assertions.build(asserter: asserter, act: "classify", object: category)
    assertion.save
    assertion
  end

  def judge_the_step(asserter)
    transition = Transition.create!(source: claim, target: conclusion)
    assertion = transition.assertions.build(asserter: asserter, act: "assert",
                                            claim: { "verdict" => "earned" })
    assertion.save
    assertion
  end

  describe "what an unresolved name does not stop" do
    it "permits classification when nothing is blocking" do
      expect(classify(classifier)).to be_persisted
    end

    # The change this file exists to record.
    it "permits classification while identity is unresolved" do
      lock!

      expect(classify(classifier)).to be_persisted
    end

    # Otherwise grounding a name would be blocked by the very flag it clears.
    it "permits the resolution that lifts the flag" do
      lock!
      mention = document.mentions.first

      expect { IdentitySentinel.verify!(mention) }.not_to raise_error
    end
  end

  describe "what it does stop" do
    it "refuses a verdict on a step while identity is unresolved" do
      lock!

      verdict = judge_the_step(classifier)

      expect(verdict).not_to be_persisted
      expect(verdict.errors[:base].join).to include "execution is locked"
    end

    it "refuses a human verdict too — the lock is not about who is asking" do
      lock!

      expect(judge_the_step(reviewer)).not_to be_persisted
    end

    it "raises when a reasoning layer asks to proceed" do
      lock!

      expect { document.require_executable! }
        .to raise_error(Document::ExecutionLocked, /Pugsley/)
    end

    it "is silent when execution may proceed" do
      expect { document.require_executable! }.not_to raise_error
    end
  end

  # Agency is preserved: a person may resolve the ambiguity and proceed. What
  # they may not do is reason past it silently.
  it "lifts once a person disposes of the flag" do
    lock!
    expect(judge_the_step(classifier)).not_to be_persisted

    document.open_stops.each { it.dispose!(as: "accepted", by: reviewer) }

    expect(judge_the_step(classifier)).to be_persisted
  end
end
