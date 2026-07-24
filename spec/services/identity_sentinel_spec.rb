require "rails_helper"

RSpec.describe IdentitySentinel do
  let(:document) { Document.create!(body: "…") }
  let(:claim)    { document.claims.create!(position: 1, text: "Wednesday left.") }

  def mention(text) = claim.mentions.create!(text: text)

  it "records a resolution as an inference when the subject is grounded" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
    m = mention("Wednesday")

    described_class.verify!(m)

    expect(m.reload.status).to eq "resolved"
    expect(m.resolution).to be_inferred
    expect(m.resolution.resolver).to eq "ReferentResolver"
    expect(m.referent.name).to eq "Wednesday"
  end

  it "locks execution rather than guessing when the subject is unknown" do
    m = mention("Pugsley")

    described_class.verify!(m)

    expect(m.reload.status).to eq "out_of_distribution"
    expect(m.referent).to be_nil
    expect(m.sentinel_flags.sole).to be_stop
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

    expect(m.sentinel_flags.sole.message).to start_with "Identity not established"
  end

  it "attributes the flag to the Identity domain" do
    Rails.application.load_seed
    m = mention("Pugsley")

    described_class.verify!(m)

    expect(m.sentinel_flags.sole.domain.key).to eq "identity"
  end

  describe "the execution lock" do
    it "stays locked while the stop is open, and lifts once disposed" do
      m = mention("Pugsley")
      described_class.verify!(m)
      expect(document.executable?).to be false

      m.sentinel_flags.sole.dispose!(as: "accepted", by: "jeff")

      expect(document.executable?).to be true
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
