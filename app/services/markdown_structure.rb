# Which lines of a text are structure rather than prose, when the text is
# markdown.
#
# The segmenter's heading rule is a heuristic operating on line geometry, and it
# has to stay timid: it once wanted to swallow a table's contents as "headings"
# because a flattened table looks exactly like a run of short unterminated
# lines. Markdown removes the guesswork. A row is a table row because a
# delimiter row says the block is a table, not because it happens to be short.
#
# So this answers with certainty where markdown speaks, and says nothing at all
# where it does not — plain prose falls through untouched and the segmenter's
# existing rules decide.
#
# Deliberately not a markdown library. A parser would build a tree and lose the
# character offsets every claim is traced by, and would interpret far more of
# the document than this needs to know.
class MarkdownStructure
  # Kinds that are part of the document but are not claims about anything.
  STRUCTURAL = %i[heading table fence_marker thematic_break].freeze

  ATX_HEADING     = /\A {0,3}\#{1,6}(\s|\z)/
  SETEXT_UNDERLINE = /\A {0,3}(=+|-{2,})\s*\z/
  THEMATIC_BREAK  = /\A {0,3}([-*_])(\s*\1){2,}\s*\z/
  FENCE           = /\A {0,3}(```|~~~)/
  # A row is only a table row if the block carries a delimiter row: |---|:--:|
  TABLE_DELIMITER = /\A\s*\|?[\s:-]*-{2,}[\s:|-]*\|?\s*\z/
  PIPE_ROW        = /\A\s*\|.*\|\s*\z|\A[^|\n]*\|[^|\n]*\|/

  Line = Data.define(:text, :char_start, :char_end, :kind) do
    def structural? = STRUCTURAL.include?(kind)
  end

  def self.for(text) = new(text)

  def initialize(text)
    @text = text.to_s
  end

  # True when the text uses any markdown block structure at all. Plain prose
  # answers false, and nothing here touches it.
  def markdown? = lines.any?(&:structural?)

  def lines = @lines ||= classify

  # Whether the span sits inside a structural block.
  def structural?(char_start, char_end)
    lines.any? { it.structural? && it.char_start < char_end && char_start < it.char_end }
  end

  # Character offsets at which a block begins or ends, so the segmenter never
  # runs a claim across a boundary markdown has already drawn.
  def boundaries
    @boundaries ||= lines.flat_map { [ it.char_start, it.char_end ] }.uniq.sort
  end

  private

  attr_reader :text

  def classify
    raw = split_lines
    table_rows = table_line_indices(raw)
    in_fence = false
    out = []

    raw.each_with_index do |(content, from, to), index|
      kind =
        if content.match?(FENCE)
          in_fence = !in_fence
          :fence_marker
        elsif in_fence
          :fenced_content
        elsif content.match?(ATX_HEADING) then :heading
        elsif content.match?(THEMATIC_BREAK) then :thematic_break
        elsif setext_heading?(raw, index) then :heading
        # The underline belongs to the heading it underlines; on its own it is
        # not a claim about anything either.
        elsif content.match?(SETEXT_UNDERLINE) && out.last&.kind == :heading then :heading
        elsif table_rows.include?(index) then :table
        else :prose
        end

      out << Line.new(text: content, char_start: from, char_end: to, kind: kind)
    end

    out
  end

  # "Heading\n=======" — the underline makes the line above a heading.
  def setext_heading?(raw, index)
    content = raw[index].first
    return false if content.strip.empty?
    return false if content.match?(SETEXT_UNDERLINE)

    following = raw[index + 1]&.first
    following.present? && following.match?(SETEXT_UNDERLINE)
  end

  # A run of pipe rows counts as a table only if one of them is a delimiter row.
  # Without that rule, any sentence containing two pipes would become a table.
  def table_line_indices(raw)
    indices = Set.new

    runs(raw) do |run|
      next unless run.any? { |i| raw[i].first.match?(TABLE_DELIMITER) && raw[i].first.include?("-") }

      run.each { indices << it }
    end

    indices
  end

  # Consecutive runs of pipe-bearing lines.
  def runs(raw)
    current = []

    raw.each_with_index do |(content, _, _), index|
      if content.match?(PIPE_ROW) || (current.any? && content.match?(TABLE_DELIMITER))
        current << index
      else
        yield current if current.size > 1
        current = []
      end
    end

    yield current if current.size > 1
  end

  def split_lines
    out = []
    offset = 0

    text.each_line do |line|
      content = line.chomp
      out << [ content, offset, offset + content.length ]
      offset += line.length
    end

    out
  end
end
