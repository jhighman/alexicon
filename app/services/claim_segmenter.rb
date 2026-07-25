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
  Segment = Data.define(:text, :char_start, :char_end)

  # A terminator may be followed by closing quotes or brackets.
  TERMINATOR = /[.!?]+["'”’)\]]*/

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
  end

  def call
    return [] if text.strip.empty?

    segments = []
    cursor = 0

    (terminator_cuts + line_cuts).uniq.sort.each do |finish|
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

  attr_reader :text

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
    Segment.new(text: stripped, char_start: start, char_end: start + stripped.length)
  end
end
