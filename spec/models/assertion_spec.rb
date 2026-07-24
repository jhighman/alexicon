require "rails_helper"

RSpec.describe Assertion do
  let(:sarah) { Referent.create!(name: "Sarah", subject: "Person", role: "Employee", primitive: "person") }
  let(:acme)  { Referent.create!(name: "Acme", subject: "Corporation", role: "Employer", primitive: "entity") }
  let(:employment) do
    Relationship.create!(source: sarah, target: acme, kind: "employment")
  end

  def assert!(act: "assert", **attrs)
    described_class.create!(asserter: acme, subject: employment, act: act, **attrs)
  end

  describe "immutability" do
    # An assertion records that a claim WAS MADE. Revising it would destroy the
    # historical record the architecture exists to preserve.
    it "cannot be modified after it is issued" do
      assertion = assert!(claim: { "title" => "Engineer" })

      expect(assertion).to be_readonly
      expect { assertion.update!(claim: { "title" => "Director" }) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "is answered by a later assertion rather than corrected in place" do
      original = assert!(claim: { "start_date" => "2020-01-01" })
      correction = assert!(act: "amend", claim: { "start_date" => "2021-01-01" },
                           supersedes: original)

      expect(correction.supersedes?(original)).to be true
      expect(original.reload.claim).to eq({ "start_date" => "2020-01-01" })
      expect(described_class.count).to eq 2
    end
  end

  describe "accountability" do
    it "requires an identifiable asserter" do
      assertion = described_class.new(subject: employment, act: "assert")

      expect(assertion).not_to be_valid
      expect(assertion.errors[:asserter]).to be_present
    end

    it "records what the asserter claimed, not whether it was true" do
      assertion = assert!(claim: { "title" => "Engineer" }, provenance: "HR system, signed")

      expect(assertion.claim).to eq({ "title" => "Engineer" })
      expect(assertion.provenance).to eq "HR system, signed"
    end
  end

  describe "recursion" do
    # The subject may be a prior assertion, so claims can challenge claims.
    it "can take another assertion as its subject" do
      original = assert!(claim: { "title" => "Engineer" })
      challenge = described_class.create!(asserter: sarah, subject: original, act: "challenge",
                                          claim: { "reason" => "title disputed" })

      expect(challenge.subject).to eq original
      expect(original.assertions).to contain_exactly(challenge)
    end
  end

  describe "temporal anchoring" do
    it "stamps the moment of assertion automatically" do
      expect(assert!.asserted_at).to be_present
    end

    it "knows whether its claim covers a given moment" do
      assertion = assert!(valid_from: 2.years.ago, valid_until: 1.year.ago)

      expect(assertion.covers?(18.months.ago)).to be true
      expect(assertion.covers?(Time.current)).to be false
    end

    it "treats an open-ended claim as covering the present" do
      expect(assert!(valid_from: 1.year.ago).covers?(Time.current)).to be true
    end

    it "rejects a window that ends before it begins" do
      assertion = described_class.new(asserter: acme, subject: employment, act: "assert",
                                       valid_from: 1.day.ago, valid_until: 2.days.ago)

      expect(assertion).not_to be_valid
    end
  end

  describe "evidence" do
    it "supports many assertions from one document, and rests on many forms" do
      contract = Evidence.create!(kind: "document", reference: "contract-1")
      email    = Evidence.create!(kind: "document", reference: "offer-email")
      a = assert!(claim: { "title" => "Engineer" })
      b = assert!(act: "amend", claim: { "title" => "Senior Engineer" })

      [ a, b ].each { EvidenceLink.create!(assertion: it, evidence: contract) }
      EvidenceLink.create!(assertion: a, evidence: email, note: "states the start date")

      expect(contract.assertions).to contain_exactly(a, b)
      expect(a.evidence).to contain_exactly(contract, email)
    end
  end
end
