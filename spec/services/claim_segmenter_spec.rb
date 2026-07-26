require "rails_helper"

RSpec.describe ClaimSegmenter do
  def segment(text) = described_class.new(text).call

  def texts(text) = segment(text).map(&:text)

  it "returns nothing for empty input" do
    expect(segment("")).to be_empty
    expect(segment("   \n ")).to be_empty
  end

  it "splits the framework's own example" do
    expect(texts("I experienced overwhelming peace. Therefore God exists."))
      .to eq [ "I experienced overwhelming peace.", "Therefore God exists." ]
  end

  it "handles questions and exclamations" do
    expect(texts("Who or what exists? Nobody knows! We proceed anyway."))
      .to eq [ "Who or what exists?", "Nobody knows!", "We proceed anyway." ]
  end

  it "keeps a trailing fragment with no terminator" do
    expect(texts("First claim. Second without a stop")).to eq [ "First claim.", "Second without a stop" ]
  end

  it "does not split on an abbreviation" do
    expect(texts("Dr. Winnicott described a defense. It is called the False Self."))
      .to eq [ "Dr. Winnicott described a defense.", "It is called the False Self." ]
  end

  it "does not split on a decimal" do
    expect(texts("Confidence was 0.94 for that claim. The next was lower."))
      .to eq [ "Confidence was 0.94 for that claim.", "The next was lower." ]
  end

  it "does not split mid-abbreviation for e.g. and i.e." do
    expect(texts("Structural pauses, e.g. caretaking, are valid. They carry no penalty."))
      .to eq [ "Structural pauses, e.g. caretaking, are valid.", "They carry no penalty." ]
  end

  it "keeps a closing quotation mark with the claim it ends" do
    expect(texts(%(He said "I am loved." Then he stopped.)))
      .to eq [ %(He said "I am loved."), "Then he stopped." ]
  end

  it "treats an ellipsis followed by a capital as one boundary" do
    expect(texts("It trailed off... Then resumed.")).to eq [ "It trailed off...", "Then resumed." ]
  end

  describe "offsets" do
    it "point at the exact span of the original text" do
      body = "  First claim.   Second claim.  "
      segments = segment(body)

      segments.each do |s|
        expect(body[s.char_start...s.char_end]).to eq s.text
      end
    end

    it "exclude surrounding whitespace" do
      segments = segment("  Only claim.  ")

      expect(segments.sole.char_start).to eq 2
      expect(segments.sole.text).to eq "Only claim."
    end

    it "never modify the source text" do
      body = "First. Second."
      original = body.dup
      segment(body)

      expect(body).to eq original
    end
  end

  # A heading carries no full stop, so on terminators alone it merged into the
  # sentence beneath it and the claim did two things at once -- the exact
  # condition the classifier is told to abstain on.
  describe "line breaks" do
    it "does not weld a heading to the sentence under it" do
      segments = described_class.new("Three Key Principles\nTrust is a discipline.").call

      expect(segments.map(&:text)).to eq [ "Three Key Principles", "Trust is a discipline." ]
    end

    it "treats a blank line as a break whatever follows" do
      segments = described_class.new("Philosophical commitment\n\nThose should never be merged.").call

      expect(segments.map(&:text)).to eq [ "Philosophical commitment", "Those should never be merged." ]
    end

    # The one case a line break must not split: hard-wrapped prose, where the
    # break falls mid-sentence. It announces itself by resuming in lower case.
    it "keeps a hard-wrapped sentence together" do
      segments = described_class.new("He said the thing\nthat mattered most to him.").call

      expect(segments.map(&:text)).to eq [ "He said the thing\nthat mattered most to him." ]
    end

    it "keeps a colon-introduced list together" do
      text = "It can be heard as:\nthe self at war with itself,\nor humanity turned against itself."

      expect(described_class.new(text).call.size).to eq 1
    end

    it "keeps offsets exact so every claim still points at its own span" do
      text = "A Heading\nThe first claim. The second claim.\n\nAnother heading"
      segments = described_class.new(text).call

      expect(segments.size).to eq 4
      segments.each { expect(text[it.char_start...it.char_end]).to eq it.text }
    end

    it "does not split on a trailing newline at the end of the text" do
      segments = described_class.new("Only one claim here.\n").call

      expect(segments.map(&:text)).to eq [ "Only one claim here." ]
    end
  end

  # A heading is part of the document but is not a claim about anything.
  describe "structure" do
    it "marks an isolated heading as structure" do
      segments = described_class.new("The Sentinel\n\nTrust is a discipline. It is not a feeling.").call

      expect(segments.first.text).to eq "The Sentinel"
      expect(segments.first).to be_structural
      expect(segments.drop(1).none?(&:structural?)).to be true
    end

    # The obvious rule swallowed 49 of one document's 306 claims, including the
    # framework's own category definitions, because a table had been flattened
    # into bare lines before it arrived. Isolation is what keeps it narrow.
    it "refuses to guess about a run of short unterminated lines" do
      table = "Category\nWhat it is\nSource of confidence\nObjective\nPublicly checkable facts"

      expect(described_class.new(table).call.none?(&:structural?)).to be true
    end

    # A trailing space is invisible in an editor and ordinary in pasted text.
    # Testing for a bare newline meant a line carrying one was not "alone on its
    # line", so every heading rule silently switched off for it — two real
    # headings in the essay under analysis were claims for that reason alone.
    it "marks a heading whose line carries a trailing space" do
      segments = described_class.new("The Sentinel \n\nTrust is a discipline. It is not a feeling.").call

      expect(segments.first.text).to eq "The Sentinel"
      expect(segments.first).to be_structural
    end

    it "marks a heading indented on its own line" do
      segments = described_class.new("It fell.\n\n   The Sentinel\t\n\nTrust is a discipline.").call

      expect(segments.find { it.text == "The Sentinel" }).to be_structural
    end

    # The tolerance is for horizontal whitespace only: a heading still has to be
    # alone, and text on the same line still means it is not.
    it "does not mark a phrase that shares its line with a sentence" do
      segments = described_class.new("It fell. The Sentinel\n\nTrust is a discipline.").call

      expect(segments.none?(&:structural?)).to be true
    end

    it "does not mark a short sentence that ends properly" do
      segments = described_class.new("It fell.\n\nI saw it happen.").call

      expect(segments.none?(&:structural?)).to be true
    end

    it "does not mark a line that ends in a colon, which introduces what follows" do
      segments = described_class.new("Polanyi reverses it:\n\nCommitment then understanding.").call

      expect(segments.first).not_to be_structural
    end

    # Without the ellipsis as a terminator this read as an unterminated line and
    # was mistaken for a heading.
    it "treats an ellipsis as ending a sentence" do
      segments = described_class.new("But here is where it gets interesting…\n\nThe wall fell.").call

      expect(segments.first).not_to be_structural
    end

    it "does not mark prose that merely lacks a full stop mid-paragraph" do
      segments = described_class.new("The wall fell. And then\nit was over.").call

      expect(segments.none?(&:structural?)).to be true
    end
  end
end
