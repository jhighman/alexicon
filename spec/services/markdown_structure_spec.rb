require "rails_helper"

# The segmenter's heading rule is geometry, and geometry cannot tell a table's
# contents from a run of headings — which is why it has to stay timid. Markdown
# removes the guesswork where the author supplied it.
RSpec.describe MarkdownStructure do
  def kinds(text) = described_class.for(text).lines.reject { it.text.strip.empty? }.map(&:kind)

  describe "headings" do
    it "recognises an ATX heading at any level" do
      expect(kinds("# One\n\n## Two\n\n###### Six\n")).to eq %i[heading heading heading]
    end

    it "recognises a setext heading by its underline" do
      expect(kinds("The Sentinel\n============\n")).to eq %i[heading heading]
    end

    it "does not take a hash inside prose for a heading" do
      expect(kinds("We tagged it #alexicon in the notes.\n")).to eq [ :prose ]
    end
  end

  describe "tables" do
    let(:table) do
      "| Category | What it is |\n|---|---|\n| Objective | Publicly checkable facts |\n"
    end

    it "recognises every row of a delimited table" do
      expect(kinds(table)).to eq %i[table table table]
    end

    # The rule that keeps prose out. Without requiring a delimiter row, any
    # sentence carrying two pipes would become a table.
    it "does not take piped prose for a table" do
      text = "The options are a | b | c, and none of them worked.\nWe moved on | eventually.\n"

      expect(kinds(text)).to eq %i[prose prose]
    end

    it "leaves prose around a table alone" do
      text = "Before the table.\n\n#{table}\nAfter the table.\n"

      expect(kinds(text)).to eq %i[prose table table table prose]
    end
  end

  describe "fenced code" do
    it "marks the fences and does not treat the contents as prose" do
      expect(kinds("```ruby\nputs 1\n```\n")).to eq %i[fence_marker fenced_content fence_marker]
    end
  end

  it "recognises a thematic break" do
    expect(kinds("Before.\n\n---\n\nAfter.\n")).to eq %i[prose thematic_break prose]
  end

  describe "plain prose" do
    let(:prose) { "The wall fell. I saw it happen.\n\nTherefore God exists.\n" }

    it "says nothing about it" do
      expect(described_class.for(prose)).not_to be_markdown
      expect(kinds(prose)).to all(eq(:prose))
    end
  end

  describe "offsets" do
    it "reports spans that point back at the original text" do
      text = "# Heading\n\nSome prose.\n"
      structure = described_class.for(text)

      heading = structure.lines.find { it.kind == :heading }
      expect(text[heading.char_start...heading.char_end]).to eq "# Heading"
    end

    it "knows whether a span sits inside a structural block" do
      text = "# Heading\n\nSome prose.\n"
      structure = described_class.for(text)

      expect(structure.structural?(0, 9)).to be true
      expect(structure.structural?(11, 22)).to be false
    end
  end
end
