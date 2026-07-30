require "rails_helper"

RSpec.describe IdentitySentinel do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0") }
  let(:identity_domain) do
    Domain.create!(framework: framework, key: "identity", name: "Identity",
                   position: 1, question: "Who or what exists?")
  end
  # A flag needs an accountable author, so the sentinel must exist before it
  # can raise one.
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system", domain: identity_domain)
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end

  let(:document) { Document.create!(body: "…") }
  let(:claim)    { document.claims.create!(position: 1, text: "Wednesday left.") }

  def mention(text) = claim.mentions.create!(text: text)

  # Every resolution in the database — all 422 of them — was asserted by the
  # Sentinel, including the ones somebody answered a STOP to make. `Mention#
  # resolution` prefers a person's resolution over a system's and that branch
  # could not fire, because no resolution was ever asserted by a person.
  #
  # Identity precedes reasoning: nothing may be predicated of an ungrounded
  # subject, so who says a name refers to something is load-bearing for every
  # judgement downstream of it.
  describe "who the record says decided" do
    it "attributes an automatic match to the Sentinel" do
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      m = mention("Wednesday")

      described_class.verify!(m)

      expect(m.resolution.asserter).to eq identity_sentinel
      expect(m.resolution).to be_inferred
      expect(m.resolution.claim["grounded"]).to be false
    end

    it "attributes a grounding to whoever decided it, not to the Sentinel" do
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      m = mention("Wednesday")

      described_class.verify!(m, by: reviewer)

      expect(m.resolution.asserter).to eq reviewer
      expect(m.resolution).not_to be_inferred
    end

    it "marks a grounded answer, so an agent's decision is not read as a match" do
      agent = Referent.create!(name: "Identity Grounder", subject: "System", role: "Reviewer",
                               primitive: "system")
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      m = mention("Wednesday")

      described_class.verify!(m, by: agent)

      expect(m.resolution.claim["grounded"]).to be true
      expect(m.resolution).to be_inferred
    end

    # The branch that could never fire.
    it "lets a person's resolution win over the Sentinel's, as the model always said it would" do
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      m = mention("Wednesday")
      described_class.verify!(m)
      theirs = Referent.create!(name: "Wednesday Adams", subject: "Person", role: "Character")
      Assertion.create!(asserter: reviewer, subject: m, object: theirs, act: "resolve", claim: {})

      expect(m.reload.resolution.asserter).to eq reviewer
      expect(m.referent).to eq theirs
    end
  end

  it "records a resolution as an inference when the subject is grounded" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
    m = mention("Wednesday")

    described_class.verify!(m)

    expect(m.reload.status).to eq "resolved"
    expect(m.resolution).to be_inferred
    expect(m.resolution.asserter).to eq identity_sentinel
    expect(m.resolution.claim["resolver"]).to eq "ReferentResolver"
    expect(m.referent.name).to eq "Wednesday"
  end

  it "locks execution rather than guessing when the subject is unknown" do
    m = mention("Pugsley")

    described_class.verify!(m)

    expect(m.reload.status).to eq "out_of_distribution"
    expect(m.referent).to be_nil
    expect(m.flags.sole).to be_stop
    expect(document.executable?).to be false
  end

  it "does not pick the likeliest candidate when several match" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
    Referent.create!(name: "Wednesday", subject: "Organisation", role: "Venue")
    m = mention("Wednesday")

    described_class.verify!(m)

    expect(m.reload.status).to eq "ambiguous"
    expect(m.resolutions).to be_empty
  end

  it "states what was not established, never who the referent is" do
    m = mention("Pugsley")

    described_class.verify!(m)

    expect(m.flags.sole.message).to start_with "Identity not established"
  end

  # A governance signal with no accountable author would be the ungrounded
  # claim this sentinel exists to refuse.
  it "attributes the flag to the Identity Sentinel, which serves the Identity domain" do
    m = mention("Pugsley")

    described_class.verify!(m)

    flag = m.flags.sole
    expect(flag.asserter).to eq identity_sentinel
    expect(flag.asserter.domain.key).to eq "identity"
  end

  describe "the execution lock" do
    it "stays locked while the stop is open, and lifts once disposed" do
      m = mention("Pugsley")
      described_class.verify!(m)
      expect(document.executable?).to be false

      m.flags.sole.dispose!(as: "accepted", by: reviewer)

      expect(document.executable?).to be true
    end

    it "records who lifted the lock, without erasing the flag" do
      m = mention("Pugsley")
      described_class.verify!(m)
      flag = m.flags.sole

      flag.dispose!(as: "accepted", by: reviewer)

      expect(flag.disposition).to eq "accepted"
      expect(flag.assertions.sole.asserter).to eq reviewer
      expect(flag.reload.message).to start_with "Identity not established"
    end

    it "reports which mentions are blocking" do
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      good = mention("Wednesday")
      bad  = mention("Pugsley")
      [ good, bad ].each { described_class.verify!(it) }

      expect(document.blocking_mentions).to contain_exactly(bad)
    end
  end
end
