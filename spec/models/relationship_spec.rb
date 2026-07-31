require "rails_helper"

# The worked example from the thesis: "Sarah works for Acme Corporation."
# Neither endpoint contains the meaning. Employment exists only as a governed
# connection between them, with its own lifecycle.
RSpec.describe Relationship do
  let(:sarah) { Referent.create!(name: "Sarah", subject: "Person", role: "Employee", primitive: "person") }
  let(:acme)  { Referent.create!(name: "Acme", subject: "Corporation", role: "Employer", primitive: "entity") }
  let(:hr)    { Referent.create!(name: "Acme HR", subject: "System", role: "Issuer", primitive: "system") }
  let(:employment) { described_class.create!(source: sarah, target: acme, kind: "employment") }

  # ADR 22: an entity does not author, so the attestations come from an officer.
  let(:registrar) do
    Referent.create!(name: "Dana Reyes", subject: "Person", role: "Registrar at Acme",
                     primitive: "person")
  end

  def assert!(act: "assert", asserter: registrar, subject: employment, **attrs)
    Assertion.create!(asserter: asserter, subject: subject, act: act, **attrs)
  end

  it "cannot connect a referent to itself" do
    loop_rel = described_class.new(source: sarah, target: sarah, kind: "employment")

    expect(loop_rel).not_to be_valid
  end

  describe "derived status" do
    it "is proposed before anything has been asserted" do
      expect(employment.status).to eq :proposed
    end

    it "becomes active once asserted" do
      assert!(claim: { "title" => "Engineer" }, valid_from: 1.year.ago)

      expect(employment.status).to eq :active
      expect(employment).to be_active
    end

    it "becomes revoked when revocation is asserted" do
      assert!(claim: { "title" => "Engineer" }, valid_from: 1.year.ago)
      assert!(act: "revoke", claim: { "reason" => "resignation" })

      expect(employment.status).to eq :revoked
    end

    it "becomes expired once the validity window has passed" do
      assert!(claim: { "title" => "Contractor" }, valid_from: 3.years.ago, valid_until: 2.years.ago)

      expect(employment.status).to eq :expired
    end

    it "is active within the window and expired outside it" do
      assert!(claim: { "title" => "Contractor" }, valid_from: 3.years.ago, valid_until: 2.years.ago)

      expect(employment.status(at: 30.months.ago)).to eq :active
      expect(employment.status(at: Time.current)).to eq :expired
    end
  end

  # The architecture preserves disagreement rather than eliminating it.
  describe "disagreement" do
    it "reports disputed while a challenge stands unanswered" do
      assert!(claim: { "title" => "Engineer" }, valid_from: 1.year.ago)
      assert!(act: "challenge", asserter: sarah, claim: { "reason" => "never held that title" })

      expect(employment.status).to eq :disputed
    end

    it "lets contradictory claims coexist without forcing a winner" do
      assert!(claim: { "title" => "Engineer" }, valid_from: 1.year.ago)
      assert!(asserter: hr, claim: { "title" => "Contractor" }, valid_from: 1.year.ago)

      expect(employment.standing_assertions.count).to eq 2
      expect(employment.status).to eq :active
    end
  end

  describe "history" do
    it "keeps the superseded claim and stops counting it as standing" do
      original = assert!(claim: { "title" => "Engineer" }, valid_from: 2.years.ago)
      assert!(act: "amend", claim: { "title" => "Senior Engineer" },
              valid_from: 1.year.ago, supersedes: original)

      expect(employment.history.count).to eq 2
      expect(employment.standing_assertions).not_to include(original)
      expect(employment.current_claim).to eq({ "title" => "Senior Engineer" })
    end

    it "has no status column — standing is derived, never stored" do
      expect(described_class.column_names).not_to include("status", "active", "valid_from")
    end

    # Deleting would erase accountable claims rather than answer them.
    it "cannot be deleted once it has been asserted about — only revoked" do
      assert!(claim: { "title" => "Engineer" })

      expect(employment.destroy).to be false
      expect(employment.errors[:base].join).to match(/assertion/i)
      expect(described_class.count).to eq 1
    end

    it "can be deleted while still merely proposed" do
      expect(employment.destroy).to be_truthy
    end
  end

  describe "evidence" do
    it "gathers evidence across every assertion concerning it" do
      contract = Evidence.create!(kind: "document", reference: "contract-1")
      a = assert!(claim: { "title" => "Engineer" })
      EvidenceLink.create!(assertion: a, evidence: contract)

      expect(employment.evidence).to contain_exactly(contract)
    end
  end

  it "exists independently of either endpoint's own attributes" do
    assert!(claim: { "title" => "Engineer" }, valid_from: 1.year.ago)

    expect(sarah.outgoing_relationships).to contain_exactly(employment)
    expect(acme.incoming_relationships).to contain_exactly(employment)
    expect(sarah.relationships).to contain_exactly(employment)
  end
end
