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
    offset = 0

    while offset < text.length && (match = TERMINATOR.match(text, offset))
      finish = match.end(0)
      if boundary?(match, finish)
        segment = build(cursor, finish)
        segments << segment if segment
        cursor = finish
      end
      offset = finish
    end

    tail = build(cursor, text.length)
    segments << tail if tail
    segments
  end

  private

  attr_reader :text

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
