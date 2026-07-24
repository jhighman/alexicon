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
end
