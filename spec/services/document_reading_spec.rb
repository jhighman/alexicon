require "rails_helper"

# The reading view shows the document that was written. Its one hard obligation
# is not to alter it: no rewriting, no summarising, and no quietly dropping the
# parts the segmenter did not claim.
RSpec.describe DocumentReading do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:body) do
    "Part One\n\nThe wall fell. I saw it happen.\n\nTherefore God exists.\n"
  end
  let(:document) { Document.create!(body: body) }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end

  let!(:categories) do
    [ [ "observation", 1, 1 ], [ "interpretive", 2, 2 ], [ "ontological", 3, 3 ] ].map do |key, pos, rank|
      ClaimCategory.create!(framework: framework, key: key, name: key.capitalize, position: pos,
                            justification_rank: rank, definition: "…", confidence_source: "…")
    end
  end

  before { DocumentIngest.call(document) }

  # The whole point of not letting a model retell the document.
  it "reassembles into exactly the text that was written" do
    reading = described_class.for(document.reload)

    expect(reading.segments.map(&:text).join).to eq body
  end

  it "keeps the blank runs between claims, which are the paragraph breaks" do
    reading = described_class.for(document.reload)

    expect(reading.segments.count { !it.claim? }).to be_positive
    expect(reading.segments.map(&:text).join).to include "\n\n"
  end

  it "covers the body once, dropping nothing and duplicating nothing" do
    reading = described_class.for(document.reload)

    expect(reading.segments.sum { it.text.length }).to eq body.length
  end

  describe "the summary" do
    it "counts what has been typed and what has not" do
      doc = document.reload
      first_claim = doc.claims.substantive.first
      first_claim.classify!(categories.first, asserter: person, confidence: 1.0)

      summary = described_class.for(doc.reload).summary

      expect(summary[:claims]).to eq doc.claims.substantive.count
      expect(summary[:classified]).to eq 1
      expect(summary[:categories]).to include [ "Observation", 1 ]
    end

    # A heading is in the document but is not a claim, so counting it among the
    # unclassified would report work outstanding that nobody should do.
    it "counts headings apart from claims" do
      summary = described_class.for(document.reload).summary

      expect(summary[:structural]).to be_positive
      expect(summary[:claims]).to eq document.claims.count - summary[:structural]
    end

    # An empty finding column is reported as empty, not left to look like a
    # clean bill of health.
    it "reports that nothing has been judged when nothing has" do
      summary = described_class.for(document.reload).summary

      expect(summary[:steps_judged]).to eq 0
      expect(summary[:unearned]).to eq 0
    end
  end

  describe "findings" do
    it "anchors an unearned step to the claim it lands on" do
      doc = document.reload
      from, to = doc.claims.first(2)
      from.classify!(categories.first, asserter: person, confidence: 1.0)
      to.classify!(categories.last, asserter: person, confidence: 1.0)
      doc.open_stops.each { it.dispose!(as: "accepted", by: person) }

      step = Transition.create!(source: from, target: to)
      step.record_verdict!("unearned", asserter: person, rationale: "no justification offered")

      reading = described_class.for(doc.reload)

      expect(reading.findings_for(to).map(&:kind)).to include :unearned
      expect(reading.findings_for(from)).to be_empty
    end

    it "anchors an open identity flag to the claim the name appears in" do
      doc = document.reload
      flagged = doc.mentions.first

      reading = described_class.for(doc)

      expect(reading.findings_for(flagged.claim).map(&:kind)).to include :flag
    end
  end

  # A guard nobody has measured is a guard nobody should rely on. On the real
  # document the floor rejected 0 of 242, which reads as a working filter unless
  # it is stated.
  describe "the confidence floor" do
    it "reports what the floor actually rejected" do
      doc = document.reload
      doc.claims.substantive.first.classify!(categories.first, asserter: person, confidence: 0.9)

      floor = described_class.for(doc.reload).summary[:confidence_floor]

      expect(floor.proposals).to eq 1
      expect(floor.rejected).to eq 0
      expect(floor).to be_inert
    end

    it "is not inert when the floor has rejected something" do
      doc = document.reload
      doc.claims.substantive.first.classify!(categories.first, asserter: person, confidence: 0.5)

      floor = described_class.for(doc.reload).summary[:confidence_floor]

      expect(floor.rejected).to eq 1
      expect(floor).not_to be_inert
      expect(floor.rate).to eq 1.0
    end

    it "says so when nothing has been classified at all" do
      floor = described_class.for(document.reload).summary[:confidence_floor]

      expect(floor.proposals).to eq 0
      expect(floor).not_to be_inert
      expect(floor.to_s).to eq "no classifications recorded"
    end
  end
end
