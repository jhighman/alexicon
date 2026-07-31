require "rails_helper"

# Ingest unwraps before it segments (ADR 23).
#
# The invariant under test is not that prose looks tidier. It is that a
# paragraph arrives at the segmenter as a paragraph, rather than as the
# line-length pieces an editor happened to break it into — because segmentation
# is a binding, and every judgement downstream inherits it ungoverned.
RSpec.describe Document, "normalisation" do
  describe "at creation" do
    it "unwraps hard-wrapped prose so a sentence is not cut at the line break" do
      document = Document.create!(body: "# A Heading\n\nThe room seemed to\ndissolve and I saw the wall collapse.\n")

      expect(document.body).to include("The room seemed to dissolve and I saw the wall collapse.")
    end

    it "keeps the text as submitted, so the transformation is recorded" do
      submitted = "The room seemed to\ndissolve.\n"
      document = Document.create!(body: submitted)

      expect(document.source_body).to eq(submitted)
      expect(document.source).to eq(submitted)
      expect(document).to be_normalised
    end

    it "says nothing changed when the document was already written in paragraphs" do
      document = Document.create!(body: "One whole sentence on one line.\n")

      expect(document).not_to be_normalised
    end

    it "leaves alone everything reflow refuses to touch" do
      document = Document.create!(body: <<~MD)
        # A Heading

        | a | b |
        |---|---|
        | 1 | 2 |

        ```
        code stays
          as is
        ```
      MD

      expect(document.body).to include("| a | b |\n|---|---|\n| 1 | 2 |")
      expect(document.body).to include("code stays\n  as is")
    end

    it "keeps a markdown hard break, which is a line the author meant to keep" do
      document = Document.create!(body: "**Sample:** one  \n**Code:** two\n")

      expect(document.body).to include("**Sample:** one  \n**Code:** two")
    end
  end

  describe "afterwards" do
    # Moving the text under a recorded reading changes what was measured without
    # changing the record that says what was measured.
    it "does not renormalise on update" do
      document = Document.create!(body: "One line here.\n")
      body = document.body

      document.update!(title: "retitled")

      expect(document.reload.body).to eq(body)
    end

    it "treats a document with no source as its own source" do
      document = Document.create!(body: "x")
      document.update_column(:source_body, nil)

      expect(document.reload.source).to eq(document.body)
      expect(document.reload).not_to be_normalised
    end
  end

  describe "what it does to segmentation" do
    it "produces one claim where the unwrapped text is one sentence" do
      wrapped = "# A Heading\n\nThe room seemed to\ndissolve and I saw the wall collapse.\n"

      claims = DocumentIngest.ingest!(body: wrapped).claims.reject(&:structural?)

      expect(claims.map(&:text)).to eq(["The room seemed to dissolve and I saw the wall collapse."])
    end

    it "leaves every claim traceable to a span of the body it was cut from" do
      document = DocumentIngest.ingest!(body: "# H\n\nOne sentence here.\nAnd a second one.\n").document

      document.claims.each do |claim|
        expect(document.body[claim.char_start...claim.char_end]).to eq(claim.text)
      end
    end
  end
end
