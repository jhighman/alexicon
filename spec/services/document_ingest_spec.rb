require "rails_helper"

RSpec.describe DocumentIngest do
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end

  def ingest(body) = described_class.ingest!(body: body)

  describe "segmentation" do
    it "turns a body into positioned claims" do
      result = ingest("I experienced overwhelming peace. Therefore God exists.")

      expect(result.claims.map(&:text))
        .to eq [ "I experienced overwhelming peace.", "Therefore God exists." ]
      expect(result.claims.map(&:position)).to eq [ 1, 2 ]
    end

    it "leaves the source text untouched and traceable by offset" do
      body = "First claim. Second claim."
      result = ingest(body)

      expect(result.document.body).to eq body
      result.claims.each do |claim|
        expect(body[claim.char_start...claim.char_end]).to eq claim.text
      end
    end
  end

  describe "identity verification" do
    it "flags an unknown subject and locks the document" do
      result = ingest("I saw Pugsley leave the house.")

      mention = result.mentions.sole
      expect(mention.text).to eq "Pugsley"
      expect(mention.status).to eq "out_of_distribution"
      expect(result).to be_blocked
      expect(result.document.executable?).to be false
    end

    it "resolves a known subject and leaves the document runnable" do
      Referent.create!(name: "Morticia", subject: "Family", role: "Mother")

      result = ingest("I saw Morticia leave the house.")

      expect(result.mentions.sole.status).to eq "resolved"
      expect(result.document.executable?).to be true
    end

    it "attributes every judgement to the Identity Sentinel" do
      result = ingest("I saw Pugsley leave.")

      expect(result.mentions.sole.flags.sole.asserter).to eq identity_sentinel
    end
  end

  describe "transitions" do
    it "connects adjacent claims" do
      result = ingest("One. Two. Three.")

      expect(result.transitions.count).to eq 2
      expect(result.transitions.map { it.from_claim.text }).to eq [ "One.", "Two." ]
    end

    # Ingest builds the graph. Judging it is the work of a sentinel that did
    # not construct it -- Chapter 6's independence requirement.
    it "records no verdict, because the builder does not judge" do
      result = ingest("One. Two.")

      transition = result.transitions.sole
      expect(transition.verdict).to eq "undetermined"
      expect(transition.status).to eq :proposed
      expect(transition.assertions).to be_empty
    end

    it "classifies nothing" do
      result = ingest("One. Two.")

      expect(result.claims.map(&:category)).to all(be_nil)
    end

    it "creates no transition for a single claim" do
      expect(ingest("Only one.").transitions).to be_empty
    end
  end

  describe "end to end" do
    it "produces a locked graph a person can then unlock" do
      result = ingest("I watched Pugsley experience peace. Therefore God exists.")
      document = result.document

      expect(document.claims.count).to eq 2
      expect(document.executable?).to be false

      document.open_stops.each { it.dispose!(as: "accepted", by: reviewer) }

      expect(document.executable?).to be true
      # Dismissing the flag does not invent an identity.
      expect(result.mentions.first.status).to eq "out_of_distribution"
    end
  end

  it "refuses to ingest the same document twice" do
    result = ingest("One. Two.")

    expect { described_class.call(result.document) }
      .to raise_error(described_class::AlreadyIngested)
  end

  it "refuses a blank body at the document boundary" do
    expect { ingest("   ") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "creates nothing for a body that segments into no claims" do
    document = Document.new(body: "…")
    document.save!(validate: false)
    document.update_column(:body, "   ")

    result = described_class.call(document)

    expect(result.claims).to be_empty
    expect(result.transitions).to be_empty
  end
end
