# Splits a text into individually classifiable claims.
#
# Sentence granularity. Both source documents use the sentence as the unit in
# every worked example -- "I experienced overwhelming peace." / "Therefore God
# exists." -- and it is the only granularity that can be decided without
# interpreting the text, which would itself be an ungoverned transformation.
#
# Deterministic on purpose. Segmentation is a binding: it decides what counts
# as a claim, and everything downstream inherits that decision. A probabilistic
# splitter would put a model's judgement underneath every later judgement,
# where nothing governs it.
#
# Offsets are document-relative and the source text is never modified, so every
# claim remains traceable to the exact span it came from.
class ClaimSegmenter
  Segment = Data.define(:text, :char_start, :char_end, :structural) do
    def structural? = structural
  end

  # A terminator may be followed by closing quotes or brackets. An ellipsis
  # ends a sentence too -- without it, "…where it gets interesting…" read as an
  # unterminated line and was mistaken for a heading.
  TERMINATOR = /[.!?…]+["'”’)\]]*/

  # A heading is short, sits on its own line, and does not end in punctuation
  # that closes a sentence.
  HEADING_MAX = 60

  # Trailing-period forms that do not end a sentence.
  ABBREVIATIONS = %w[
    mr mrs ms dr prof sr jr st rev hon capt sgt lt gen
    vs etc cf al inc ltd co corp dept est approx
    fig ch no vol pp ed eds trans
    jan feb mar apr jun jul aug sept sep oct nov dec
    e.g i.e a.m p.m u.s u.k
  ].freeze

  def initialize(text)
    @text = text.to_s
    @markdown = MarkdownStructure.for(@text)
  end

  def call
    return [] if text.strip.empty?

    segments = []
    cursor = 0

    # Markdown block edges are cuts too: a claim must never run from a heading
    # into the paragraph beneath it, or across a table row.
    cuts = terminator_cuts + line_cuts
    cuts += markdown.boundaries if markdown.markdown?

    cuts.uniq.sort.each do |finish|
      next if finish <= cursor

      segment = build(cursor, finish)
      segments << segment if segment
      cursor = finish
    end

    tail = build(cursor, text.length)
    segments << tail if tail
    segments
  end

  private

  attr_reader :text, :markdown

  def terminator_cuts
    cuts = []
    offset = 0

    while offset < text.length && (match = TERMINATOR.match(text, offset))
      finish = match.end(0)
      cuts << finish if boundary?(match, finish)
      offset = finish
    end

    cuts
  end

  # A heading has no full stop, so on terminators alone it merged into the
  # sentence beneath it: "Three Key Principles\nTrust is the discipline of..."
  # arrived as one claim doing two things at once, which is precisely the
  # condition the classifier is told to abstain on.
  #
  # A line break is structure that is present in the text, not something read
  # into it, so using it needs no interpretation. The one case it must not
  # break is hard-wrapped prose, where a break falls mid-sentence -- and that
  # case announces itself, because the next line resumes in lower case.
  def line_cuts
    cuts = []
    offset = 0

    while (match = /\n[ \t]*/.match(text, offset))
      cuts << match.end(0) if line_boundary?(match)
      offset = match.end(0)
      break if offset >= text.length
    end

    cuts
  end

  def line_boundary?(match)
    rest = text[match.end(0)..]
    return false if rest.nil? || rest.strip.empty?

    # A blank line is a break between blocks whatever follows it.
    return true if match[0].count("\n") > 1

    !rest.match?(/\A[a-z]/)
  end

  # A terminator ends a claim when what follows looks like a new sentence and
  # what precedes it is not an abbreviation or a decimal.
  def boundary?(match, finish)
    return true if finish >= text.length
    return false if decimal?(match)
    return false if abbreviation?(match)

    rest = text[finish..]
    return true if rest.strip.empty?
    # Must be separated by whitespace, and resume with something sentence-like.
    return false unless rest.start_with?(/\s/)

    rest.lstrip.match?(/\A["'“‘(\[]?[A-Z0-9]/)
  end

  def decimal?(match)
    return false if match.begin(0).zero?

    before = text[match.begin(0) - 1]
    after  = text[match.end(0)]
    before&.match?(/\d/) && after&.match?(/\d/)
  end

  def abbreviation?(match)
    preceding = text[0...match.begin(0)]
    word = preceding[/[\w.]+\z/]&.downcase
    return false if word.blank?

    ABBREVIATIONS.include?(word) || ABBREVIATIONS.include?(word.delete("."))
  end

  # Offsets point at the trimmed text, so a claim never carries surrounding
  # whitespace it did not contain.
  def build(from, to)
    raw = text[from...to].to_s
    stripped = raw.strip
    return nil if stripped.empty?

    start = from + raw.index(stripped)
    Segment.new(text: stripped, char_start: start, char_end: start + stripped.length,
                structural: heading?(stripped, start))
  end

  # Deliberately narrow, and it stays narrow.
  #
  # The obvious rule -- "short, alone on its line, no full stop" -- swallowed
  # 49 of this document's 306 claims, including the framework's own category
  # definitions, because a table had been flattened into bare lines before it
  # ever arrived. Marking real content as structure hides it from every later
  # judgement, which is a silent loss and worse than leaving a heading in.
  #
  # So the rule also requires ISOLATION: neither neighbouring line may be
  # heading-shaped. A run of short unterminated lines is a table or a list, and
  # this refuses to guess about those.
  # Where markdown speaks it decides, with certainty and without geometry: a row
  # is a table row because a delimiter row said so, not because it is short.
  #
  # Where it says nothing, the heuristic still runs. Making markdown
  # all-or-nothing would mean one stray horizontal rule silently switched
  # heading detection off for the rest of a mostly-plain document.
  def heading?(candidate, start)
    return true if markdown.structural?(start, start + candidate.length)
    return true if lead_in?(candidate, start)

    return false unless heading_shaped?(candidate)
    return false unless own_line?(candidate, start)

    [ line_before(start), line_after(start + candidate.length) ]
      .compact.none? { heading_shaped?(it) }
  end

  # A short line ending in a colon, alone on its line, announces what follows
  # rather than claiming anything itself: "Postscript:", "What I learned in
  # this:", "The Enlightenment model is:". The claim is the text underneath.
  #
  # This is a JUDGEMENT rather than a derivation, and it has a known cost, so
  # ADR 16 records it. "Polanyi reverses it:" does predicate — it asserts that
  # Polanyi reverses it — and this rule marks it structure anyway, because
  # separating it from "Postscript:" means deciding whether a line predicates,
  # and that is interpreting the text. Segmentation refuses to interpret,
  # because everything downstream inherits the decision ungoverned. Given the
  # choice between two rules that are each wrong somewhere, the framework's
  # authors chose this one.
  #
  # No isolation test, unlike `heading?`. Isolation exists because a RUN of
  # short unterminated lines is a flattened table whose cells may be real
  # content; a run of colon-terminated lines is not a shape tables take. The
  # length bound still applies, so a full sentence that happens to end in a
  # colon stays a claim.
  def lead_in?(candidate, start)
    return false if candidate.length > HEADING_MAX
    return false unless candidate.match?(/:["'”’)\]]*\z/)

    own_line?(candidate, start)
  end

  def heading_shaped?(line)
    stripped = line.to_s.strip
    return false if stripped.empty? || stripped.length > HEADING_MAX

    !stripped.match?(/[.!?…:,;]["'”’)\]]*\z/)
  end

  # Trailing spaces before a newline are invisible in an editor and common in
  # pasted text. Testing for a bare "\n" meant "Postscript: \n" was not alone on
  # its line and no heading rule could reach it — the whole of heading detection
  # silently switched off for any line someone had left a space on.
  def own_line?(candidate, start)
    finish = start + candidate.length
    before = start.zero? || text[0...start].match?(/\n[ \t]*\z/)
    after = finish >= text.length || text[finish..].match?(/\A[ \t]*(\n|\z)/)
    before && after
  end

  def line_before(start) = text[0...start].to_s.lines.map(&:chomp).reverse.find(&:present?)

  def line_after(finish) = text[finish..].to_s.lines.map(&:chomp).find(&:present?)
end
