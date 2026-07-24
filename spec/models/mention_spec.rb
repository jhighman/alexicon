require "rails_helper"

# Status is read from the mention's standing judgements, not remembered
# alongside them. A cache that can disagree with the record it summarises is
# the current-state model the rest of this schema has been removing.
RSpec.describe Mention do
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let(:document) { Document.create!(body: "Wednesday left.") }
  let(:claim)    { document.claims.create!(position: 1, text: "Wednesday left.") }

  def mention(text) = claim.mentions.create!(text: text)

  it "has no status column" do
    expect(described_class.column_names).not_to include("status")
  end

  it "is unresolved before anything has judged it" do
    m = mention("Wednesday")

    expect(m.status).to eq "unresolved"
    expect(m).not_to be_anchored
  end

  it "reports the Entity Noise condition the flag detected" do
    m = mention("Pugsley")
    IdentitySentinel.verify!(m)

    expect(m.status).to eq "out_of_distribution"
    expect(m.flags.sole.claim["noise"]).to eq "out_of_distribution"
  end

  it "distinguishes ambiguity from absence" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
    Referent.create!(name: "Wednesday", subject: "Organisation", role: "Venue")
    m = mention("Wednesday")
    IdentitySentinel.verify!(m)

    expect(m.status).to eq "ambiguous"
  end

  it "reports an incomplete passport as unanchored" do
    Referent.create!(name: "Gomez", subject: "Family")
    m = mention("Gomez")
    IdentitySentinel.verify!(m)

    expect(m.status).to eq "unanchored"
  end

  it "is resolved once a referent is established" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
    m = mention("Wednesday")
    IdentitySentinel.verify!(m)

    expect(m.status).to eq "resolved"
    expect(m).to be_anchored
  end

  # The failure the column allowed: a stale status surviving a re-check.
  describe "re-verification" do
    it "supersedes the earlier judgement so exactly one stands" do
      m = mention("Wednesday")
      IdentitySentinel.verify!(m)
      expect(m.status).to eq "out_of_distribution"

      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      IdentitySentinel.verify!(m)

      expect(m.status).to eq "resolved"
      expect(m.assertions.standing.count).to eq 1
      expect(m.flags).to be_empty
    end

    it "keeps the superseded judgement in the record" do
      m = mention("Wednesday")
      IdentitySentinel.verify!(m)
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      IdentitySentinel.verify!(m)

      expect(m.assertions.count).to eq 2
      expect(m.assertions.acting("flag").sole.claim["noise"]).to eq "out_of_distribution"
    end

    # Disposing of a flag lifts the execution lock. It does not establish an
    # identity that was never established.
    it "stays unresolved after a person merely dismisses the flag" do
      m = mention("Pugsley")
      IdentitySentinel.verify!(m)

      m.flags.sole.dispose!(as: "accepted", by: reviewer)

      expect(m.status).to eq "out_of_distribution"
      expect(document.executable?).to be true
    end
  end

  describe "scopes" do
    it "separates resolved mentions from blocking ones" do
      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      good = mention("Wednesday")
      bad  = mention("Pugsley")
      [ good, bad ].each { IdentitySentinel.verify!(it) }

      expect(described_class.resolved).to contain_exactly(good)
      expect(described_class.blocking).to contain_exactly(bad)
    end

    it "agrees with the per-record status after re-verification" do
      m = mention("Wednesday")
      IdentitySentinel.verify!(m)
      expect(described_class.blocking).to contain_exactly(m)

      Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")
      IdentitySentinel.verify!(m)

      expect(described_class.blocking).to be_empty
      expect(described_class.resolved).to contain_exactly(m)
    end
  end
end
