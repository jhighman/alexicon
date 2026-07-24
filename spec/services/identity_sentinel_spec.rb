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
