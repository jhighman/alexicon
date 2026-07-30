require "rails_helper"

# A flag is an assertion: a sentinel claiming that the conditions for
# proceeding have not been satisfied. It never asserts that a claim is false,
# or that an author is wrong.
#
# Its disposition is a further assertion ABOUT it, so accepting or rejecting a
# flag records a second accountable judgement rather than overwriting the first.
RSpec.describe "flags as assertions" do
  let(:document) { Document.create!(body: "…") }
  let(:sentinel) do
    Referent.create!(key: "test-sentinel", name: "Test Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end
  let(:person) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let(:transition) do
    a = document.claims.create!(position: 1, text: "one")
    b = document.claims.create!(position: 2, text: "two")
    Transition.create!(source: a, target: b)
  end

  def flag!(severity: "concern", message: "conditions not satisfied")
    Assertion.create!(asserter: sentinel, subject: transition, act: "flag",
                      claim: { "severity" => severity, "message" => message })
  end

  it "is attributed to an accountable sentinel" do
    expect(flag!.asserter).to eq sentinel
  end

  it "carries its severity and message in the claim" do
    flag = flag!(severity: "stop", message: "Identity not established")

    expect(flag).to be_flag
    expect(flag.severity).to eq "stop"
    expect(flag.message).to eq "Identity not established"
    expect(flag).to be_stop
  end

  it "rejects a severity outside the permitted set" do
    flag = Assertion.new(asserter: sentinel, subject: transition, act: "flag",
                         claim: { "severity" => "catastrophic", "message" => "…" })

    expect(flag).not_to be_valid
  end

  describe "disposition" do
    it "is open until somebody answers it — absence, not a stored default" do
      flag = flag!

      expect(flag.disposition).to eq "open"
      expect(flag).to be_open
      expect(flag.assertions).to be_empty
    end

    it "records who disposed of it as a separate accountable assertion" do
      flag = flag!

      disposition = flag.dispose!(as: "rejected", by: person)

      expect(flag.disposition).to eq "rejected"
      expect(disposition.asserter).to eq person
      expect(disposition.subject).to eq flag
    end

    # The whole point of the merge: the flag is not overwritten.
    it "leaves the original flag untouched" do
      flag = flag!(severity: "stop", message: "Identity not established")

      flag.dispose!(as: "accepted", by: person)

      expect(flag.reload.claim).to eq({ "severity" => "stop",
                                        "message" => "Identity not established" })
      expect(flag).to be_readonly
    end

    it "lets a later disposition supersede an earlier one, keeping both" do
      flag = flag!
      first = flag.dispose!(as: "rejected", by: person)
      Assertion.create!(asserter: person, subject: flag, act: "accept",
                        claim: { "disposition" => "accepted" }, supersedes: first)

      expect(flag.disposition).to eq "accepted"
      expect(flag.assertions.count).to eq 2
    end

    it "refuses an unknown disposition" do
      expect { flag!.dispose!(as: "ignored", by: person) }.to raise_error(ArgumentError)
    end

    # Two reviewers are not resolved by whichever of them went second. This took
    # the latest disposal of any kind, so one person accepting after another had
    # rejected made the rejection vanish from every read while remaining in the
    # record — disagreement preserved in storage and destroyed where anyone looks.
    describe "when two people disagree" do
      let(:other) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

      it "reports the split rather than the later answer" do
        flag = flag!
        flag.dispose!(as: "rejected", by: person)
        flag.dispose!(as: "accepted", by: other)

        expect(flag.disposition).to eq Assertion::CONTESTED
        expect(flag).to be_contested
        expect(flag).not_to be_open
      end

      it "keeps both positions standing and attributable" do
        flag = flag!
        flag.dispose!(as: "rejected", by: person)
        flag.dispose!(as: "accepted", by: other)

        by_referent = flag.disposals.values.to_h { [ it.asserter.name, it.act ] }

        expect(by_referent).to eq("Jeff" => "reject", "Ana" => "accept")
      end

      it "does not call one person changing their own mind a disagreement" do
        flag = flag!
        flag.dispose!(as: "rejected", by: person)
        flag.dispose!(as: "accepted", by: person)

        expect(flag.disposition).to eq "accepted"
        expect(flag).not_to be_contested
      end

      it "clears once the dissenter comes round" do
        flag = flag!
        flag.dispose!(as: "rejected", by: person)
        flag.dispose!(as: "accepted", by: other)
        flag.dispose!(as: "accepted", by: person)

        expect(flag.disposition).to eq "accepted"
      end
    end
  end

  it "is reachable from the subject it concerns" do
    flag = flag!

    expect(transition.flags).to contain_exactly(flag)
  end

  it "no longer has a table of its own" do
    expect(ActiveRecord::Base.connection.table_exists?("sentinel_flags")).to be false
  end
end
