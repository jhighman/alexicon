require "rails_helper"

# The extractor proposes; the Sentinel disposes. It never decides what a name
# refers to, and never decides that an unrecognised name is not a name.
RSpec.describe MentionExtractor do
  let(:document) { Document.create!(body: "…") }

  def claim(text, char_start: 0)
    document.claims.create!(position: document.claims.count + 1, text: text,
                            char_start: char_start, char_end: char_start + text.length)
  end

  # A known form was matched as a bare substring, so every short name ever
  # grounded became a landmine in every document written afterwards. A referent
  # named "Eve", grounded once while reading an essay, produced 36 mentions in
  # an unrelated letter — whenever, even, eleven — each raising an identity STOP,
  # and a STOP blocks governance. A name from one document could halt the
  # analysis of another it never appeared in.
  describe "a known name inside another word" do
    before { Referent.create!(name: "Eve", subject: "Person", role: "Figure", primitive: "person") }

    def names_in(text) = described_class.new(claim(text)).call.map(&:text)

    it "is not a mention" do
      expect(names_in("I can move whenever I feel like it.")).not_to include "eve"
      expect(names_in("It explains the eleven traps of life.")).to be_empty
      expect(names_in("A counter top, even with granite.")).to be_empty
    end

    it "still finds the name standing on its own" do
      expect(names_in("A man will meet Eve.")).to include "Eve"
    end

    # The case-insensitivity was deliberate and stays: a known referent should
    # be recognised in lower case. Only the substring matching was the bug.
    it "still finds it in lower case" do
      expect(names_in("he met eve on the path")).to include "eve"
    end

    it "still finds it possessive, where the next character is not alphanumeric" do
      expect(names_in("That was Eve's choice.")).to include "Eve"
    end

    it "does not match it hyphenated into a compound word" do
      expect(names_in("The evening was long.")).to be_empty
    end
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
