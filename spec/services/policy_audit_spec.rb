require "rails_helper"

RSpec.describe PolicyAudit do
  before do
    original, $stdout = $stdout, StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original
  end

  let(:policy) { Policy.find_by!(key: "anti-discrimination") }

  it "passes the reference scorer and records that it did" do
    result = described_class.call

    expect(result).to be_holds
    expect(result.criterion).to eq "gap invariance"
    expect(result.detail).to include "score is unchanged"
  end

  # "We checked" is itself a claim, so it is recorded as one.
  it "records the audit as an attributable assertion against the policy" do
    result = described_class.call

    expect(result.assertion.subject).to eq policy
    expect(result.assertion.asserter.key).to eq "governance-sentinel"
    expect(result.assertion.claim).to include("audit" => "policy", "holds" => true,
                                              "scorer" => "EquitableBaseline")
  end

  it "makes the policy report itself as enforced" do
    expect(policy.enforced?).to be false

    described_class.call

    expect(policy.reload.enforced?).to be true
  end

  # An architecture that only writes down its passes keeps a marketing record,
  # not an audit trail.
  it "records a failing audit rather than staying silent" do
    penalising = Class.new do
      def call(timeline) = timeline.established_kinds.size - timeline.gaps.size
      def to_proc = method(:call).to_proc
    end.new

    result = described_class.call(scorer: penalising)

    expect(result).not_to be_holds
    expect(result.detail).to include "score changed"
    expect(result.assertion.claim["holds"]).to be false
    expect(policy.reload.enforced?).to be false
  end

  it "attributes the audit to whoever ran it" do
    auditor = Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")

    result = described_class.call(auditor: auditor)

    expect(result.assertion.asserter).to eq auditor
  end
end

RSpec.describe Timeline do
  let(:sarah) { Referent.create!(name: "Sarah", subject: "Person", role: "Employee", primitive: "person") }
  let(:acme)  { Referent.create!(name: "Acme", subject: "Corporation", role: "Employer", primitive: "entity") }

  def employment(from:, to:)
    relationship = Relationship.create!(source: sarah, target: acme, kind: "employment")
    Assertion.create!(asserter: acme, subject: relationship, act: "assert",
                      claim: { "title" => "Engineer" }, valid_from: from, valid_until: to)
    relationship
  end

  it "reconstructs spans from dated assertions" do
    employment(from: 8.years.ago, to: 6.years.ago)
    employment(from: 3.years.ago, to: 1.year.ago)

    expect(Timeline.new(sarah).spans.size).to eq 2
  end

  it "reports the period between them as a gap and nothing more" do
    employment(from: 8.years.ago, to: 6.years.ago)
    employment(from: 3.years.ago, to: 1.year.ago)

    gap = Timeline.new(sarah).gaps.sole

    expect(gap.days).to be_within(40).of(3 * 365)
    expect(gap).not_to respond_to(:penalty)
    expect(gap).not_to respond_to(:score)
  end

  # An undated claim anchors nothing — the timeline is read from fixed points,
  # not from a document's apparent continuity.
  it "ignores an assertion with no start date" do
    relationship = Relationship.create!(source: sarah, target: acme, kind: "employment")
    Assertion.create!(asserter: acme, subject: relationship, act: "assert", claim: {})

    expect(Timeline.new(sarah).spans).to be_empty
  end

  it "counts only evidenced assertions as anchors" do
    relationship = employment(from: 5.years.ago, to: 3.years.ago)
    expect(Timeline.new(sarah).anchors).to be_empty

    contract = Evidence.create!(kind: "document", reference: "contract-1")
    EvidenceLink.create!(assertion: relationship.assertions.first, evidence: contract)

    expect(Timeline.new(sarah).anchors.size).to eq 1
  end
end
