require "rails_helper"

# Prose is wrapped in the source and then interpolated into, so the rendered
# line breaks land wherever the values happened to fall. This fixes that once,
# at the end. What it must not do is touch anything where a line break carries
# meaning.
RSpec.describe MarkdownReflow do
  def reflow(text, width: 40) = described_class.call(text, width: width)

  describe "prose" do
    it "rewraps a paragraph broken at a ragged column" do
      ragged = "28 of 104 steps were judged unearned — the\nsecond claim asserts more."

      expect(reflow(ragged)).to eq "28 of 104 steps were judged unearned —\nthe second claim asserts more."
    end

    it "keeps every word, in order" do
      text = "one two three four five six seven eight nine ten eleven twelve"

      expect(reflow(text).split(/\s+/)).to eq text.split(/\s+/)
    end

    it "never exceeds the width" do
      text = (1..40).map { "word#{it}" }.join(" ")

      expect(reflow(text).lines.map(&:chomp).map(&:length).max).to be <= 40
    end

    it "leaves a word longer than the width alone rather than breaking it" do
      expect(reflow("short #{'x' * 60}")).to include "x" * 60
    end

    it "keeps blocks separated" do
      expect(reflow("first para\n\nsecond para")).to eq "first para\n\nsecond para"
    end
  end

  # Rewrapping a table row destroys the table.
  describe "what it must not touch" do
    it "leaves a table exactly as it was" do
      table = "| Move | Steps |\n|---|---|\n| observation → interpretive | 10 |"

      expect(reflow(table)).to eq table
    end

    it "leaves a heading alone however long" do
      heading = "## Where a step claimed more than the one before it supported"

      expect(reflow(heading)).to eq heading
    end

    it "leaves a fenced block alone, blank lines and all" do
      code = "```\nline one\n\nline two that is quite long indeed and would wrap\n```"

      expect(reflow(code)).to eq code
    end

    it "leaves a horizontal rule alone" do
      expect(reflow("---")).to eq "---"
    end
  end

  describe "blockquotes" do
    it "rewraps the body and keeps the marker on every line" do
      quote = "> a warning that was wrapped\n> at some other width entirely"

      result = reflow(quote)

      expect(result.lines.map(&:chomp)).to all(start_with(">"))
      expect(result).to include "a warning that was wrapped at some"
    end

    it "does not let the marker push a line past the width" do
      quote = "> #{(1..30).map { "word#{it}" }.join(' ')}"

      expect(reflow(quote).lines.map(&:chomp).map(&:length).max).to be <= 40
    end

    # A bare `>` never reaches `blocks` as a blank line, so the whole quote
    # arrives as one block and the break has to survive here or nowhere. It did
    # not: two paragraphs of a report caveat were being run into one sentence.
    it "keeps a paragraph break inside the quote" do
      quote = "> first thing said here\n>\n> second thing said here"

      result = reflow(quote)

      expect(result).to include "here\n>\n> second"
      expect(result).not_to include "first thing said here second"
    end

    it "keeps every paragraph of a three-paragraph quote apart" do
      quote = "> one\n>\n> two\n>\n> three"

      expect(reflow(quote)).to eq "> one\n>\n> two\n>\n> three"
    end
  end

  describe "lists" do
    it "wraps an item with a hanging indent under the text" do
      list = "- **Whether any of it is true.** Every figure here is the system's reading."

      lines = reflow(list).lines.map(&:chomp)

      expect(lines.first).to start_with "- **Whether"
      expect(lines.drop(1)).to all(start_with("  "))
    end

    it "keeps a line that introduces the list rather than dropping it" do
      list = "**What this cannot tell you.**\n- the first thing\n- the second thing"

      result = reflow(list, width: 60)

      expect(result).to start_with "**What this cannot tell you.**"
      expect(result.lines.map(&:chomp).count { it.start_with?("- ") }).to eq 2
    end

    it "keeps separate items separate" do
      list = "- first item here\n- second item here"

      expect(reflow(list).lines.map(&:chomp).count { it.start_with?("- ") }).to eq 2
    end

    it "joins a continuation line into its item before rewrapping" do
      list = "- an item that was\n  broken mid sentence"

      expect(reflow(list, width: 60)).to eq "- an item that was broken mid sentence"
    end
  end

  # Two trailing spaces are a markdown hard break, and the measurements use them
  # to keep Sample, Conditions and Code as separate lines. Joining across one
  # ran three facts into a sentence.
  describe "hard breaks" do
    it "keeps a break the author put there" do
      text = "**Sample:** claims 20  \n**Code:** `abc1234`"

      result = reflow(text, width: 60)

      expect(result).to include "**Sample:** claims 20  \n**Code:**"
    end

    it "still wraps within each piece" do
      long = (1..12).map { "word#{it}" }.join(" ")
      result = reflow("#{long}  \nsecond piece", width: 30)

      expect(result.lines.map(&:chomp).map(&:length).max).to be <= 32
      expect(result).to include "second piece"
    end
  end

  it "is idempotent" do
    text = "## Heading\n\nsome prose that will wrap at this width\n\n| a | b |\n|---|---|"

    once = reflow(text)

    expect(reflow(once)).to eq once
  end
end
