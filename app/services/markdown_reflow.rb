# Rewraps generated markdown after interpolation, not before it.
#
# A heredoc wraps at the column the source happened to break at, and then a
# `#{}` expands to something a different length, so the rendered prose breaks
# mid-sentence at a ragged column:
#
#   28 of 104 steps were judged **unearned** — the
#   second claim asserts something the first does not carry.
#
# A markdown renderer joins those lines and nobody notices. A person reading the
# raw output does, and it is the particular tell that makes a generated document
# look generated. So prose is reflowed once, at the end, when every value is
# known.
#
# What it must not touch: tables, headings, rules, fences and their contents.
# Rewrapping a table row destroys it, and rewrapping code changes what the code
# says.
module MarkdownReflow
  WIDTH = 80

  TABLE   = /\A\s*\|/
  HEADING = /\A\s*\#/
  RULE    = /\A\s*(-{3,}|\*{3,}|_{3,})\s*\z/
  FENCE   = /\A\s*(```|~~~)/
  QUOTE   = /\A\s*>/
  BULLET  = /\A(\s*)([-*+]|\d+\.)\s+(.*)\z/
  # Two trailing spaces are a markdown hard break. Joining across one destroys a
  # line the author meant to keep — `**Sample:**` and `**Code:**` are separate
  # facts about a measurement, and reflow ran them into a sentence.
  HARD_BREAK = /\s{2,}\z/

  # Wide enough that `fill` never wraps, so a block becomes one line. Reflowing
  # to a finite width would leave the prose hard-wrapped at that width, which is
  # the condition the unwrap exists to remove.
  UNWRAPPED = 1 << 30

  module_function

  # Join every hard-wrapped prose line in a block onto one line, leaving
  # everything reflow already refuses to touch — tables, headings, rules,
  # fences, hard breaks — exactly as it found them.
  #
  # Ingest calls this so the segmenter is not handed a paragraph pre-cut into
  # line-length pieces. See ADR 23.
  # The trailing newline is put back, because `call` joins blocks and drops it.
  # Without that, unwrapping a document already written in whole paragraphs
  # still changed it by one character, and `Document#normalised?` answered true
  # for every document ever ingested — a flag that is always set says nothing.
  def unwrap(markdown)
    out = call(markdown, width: UNWRAPPED)
    markdown.to_s.end_with?("\n") && !out.end_with?("\n") ? "#{out}\n" : out
  end

  def call(markdown, width: WIDTH)
    blocks(markdown).map { reflow_block(it, width) }.join("\n\n")
  end

  # Blank lines separate blocks; everything inside a fence is one block whatever
  # blank lines it contains.
  def blocks(markdown)
    out, current, fenced = [], [], false

    markdown.to_s.lines.map(&:chomp).each do |line|
      fenced = !fenced if line.match?(FENCE)

      if line.strip.empty? && !fenced
        out << current unless current.empty?
        current = []
      else
        current << line
      end
    end
    out << current unless current.empty?
    out
  end

  def reflow_block(lines, width)
    return lines.join("\n") if lines.any? { it.match?(FENCE) }
    return lines.join("\n") if lines.all? { it.match?(TABLE) || it.match?(RULE) }
    return lines.join("\n") if lines.first.match?(HEADING)
    return quote(lines, width) if lines.first.match?(QUOTE)
    return bullets(lines, width) if lines.any? { it.match?(BULLET) }

    segments(lines).map { fill(it.join(" "), width) }.then { rejoin(it) }
  end

  # A block splits at every hard break; each piece wraps on its own and the
  # break is put back.
  def segments(lines)
    out, current = [], []

    lines.each do |line|
      current << line
      next unless line.match?(HARD_BREAK)

      out << current
      current = []
    end
    out << current unless current.empty?
    out
  end

  def rejoin(wrapped)
    wrapped.each_with_index.map do |lines, index|
      body = lines.join("\n")
      index < wrapped.size - 1 ? "#{body}  " : body
    end.join("\n")
  end

  # A blockquote keeps its marker on every line, so it is stripped, wrapped, and
  # put back.
  #
  # A bare `>` is a paragraph break inside the quote, and it does not survive
  # `blocks` — nothing there is blank, so the whole quote arrives as one block.
  # Joining across it ran two paragraphs of a caveat into one, which is the same
  # data loss the list preamble had: the text is still there, but the reader is
  # told two separate things as though they were one.
  def quote(lines, width)
    wrapped = paragraphs(lines.map { it.sub(/\A\s*>\s?/, "") })
                .map { |para| fill(para.join(" "), width - 2).map { "> #{it}".rstrip } }

    wrapped.flat_map.with_index { |para, i| i.zero? ? para : [ ">", *para ] }.join("\n")
  end

  def paragraphs(lines)
    lines.chunk_while { |a, b| !a.strip.empty? && !b.strip.empty? }
         .map { |chunk| chunk.reject { it.strip.empty? } }
         .reject(&:empty?)
  end

  # Each item is its own paragraph, wrapped with a hanging indent so the
  # continuation lines sit under the text rather than under the marker.
  # A list is often introduced by a line that is not itself an item — the caveats
  # block leads with "**What this cannot tell you.**". Dropping it silently was
  # the first bug this class had, and a spec for the report caught it.
  def bullets(lines, width)
    preamble, items, current = [], [], nil

    lines.each do |line|
      if (m = line.match(BULLET))
        items << current if current
        current = { indent: m[1], marker: m[2], text: m[3] }
      elsif current
        current[:text] = "#{current[:text]} #{line.strip}"
      else
        preamble << line
      end
    end
    items << current if current

    out = []
    out << fill(preamble.join(" "), width).join("\n") if preamble.any?
    out.concat(items.map { item(it, width) })
    out.join("\n")
  end

  def item(parts, width)
    lead = "#{parts[:indent]}#{parts[:marker]} "
    hang = " " * lead.length
    wrapped = fill(parts[:text], width - lead.length)
    ([ "#{lead}#{wrapped.first}" ] + wrapped.drop(1).map { "#{hang}#{it}" }).join("\n")
  end

  # Greedy fill. Counts characters rather than bytes, so an em dash costs one.
  def fill(text, width)
    lines = []
    current = +""

    text.split(/\s+/).reject(&:empty?).each do |word|
      if current.empty?
        current = +word
      elsif current.length + 1 + word.length <= width
        current << " " << word
      else
        lines << current
        current = +word
      end
    end

    lines << current unless current.empty?
    lines.presence || [ "" ]
  end
end
