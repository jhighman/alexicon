require "rails_helper"

# The extractor proposes; the Sentinel disposes. It never decides what a name
# refers to, and never decides that an unrecognised name is not a name.
RSpec.describe MentionExtractor do
  let(:document) { Document.create!(body: "…") }

  def claim(text, char_start: 0)
    document.claims.create!(position: document.claims.count + 1, text: text,
                            char_start: char_start, char_end: char_start + text.length)
  end

  def extract(text, **) = described_class.new(claim(text, **)).call

  def texts(text, **) = extract(text, **).map(&:text)

  it "proposes an unfamiliar capitalised name" do
    expect(texts("Pugsley left the house.")).to eq [ "Pugsley" ]
  end

  # Without this the Sentinel would never see an unknown subject, and the
  # system would reason past every referent it had never met.
  it "proposes names absent from the graph, so they can be flagged" do
    expect(texts("Morticia met Gomez.")).to contain_exactly("Morticia", "Gomez")
  end

  it "ignores sentence-initial function words" do
    expect(texts("Therefore God exists.")).to eq [ "God" ]
    expect(texts("This is a claim.")).to be_empty
    expect(texts("I experienced overwhelming peace.")).to be_empty
  end

  it "keeps a multi-word name whole" do
    expect(texts("Wednesday Addams left.")).to eq [ "Wednesday Addams" ]
  end

  it "prefers the longest span where candidates overlap" do
    Referent.create!(name: "Wednesday", subject: "Family", role: "Sister")

    expect(texts("Wednesday Addams left.")).to eq [ "Wednesday Addams" ]
  end

  it "recognises a known referent even in lower case" do
    Referent.create!(name: "Acme", subject: "Corporation", role: "Employer")

    expect(texts("she works for acme now.")).to include "acme"
  end

  it "recognises a declared alias" do
    addams = Referent.create!(name: "Wednesday Addams", subject: "Family", role: "Sister")
    addams.referent_aliases.create!(name: "Wednesday")

    expect(texts("Wednesday left.")).to eq [ "Wednesday" ]
  end

  describe "offsets" do
    it "are document-relative, not claim-relative" do
      body = "First claim. Pugsley left."
      doc = Document.create!(body: body)
      c = doc.claims.create!(position: 1, text: "Pugsley left.", char_start: 13, char_end: 26)

      candidate = described_class.new(c).call.sole

      expect(body[candidate.char_start...candidate.char_end]).to eq "Pugsley"
    end
  end
end
