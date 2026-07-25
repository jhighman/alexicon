# What the grammar of a claim says about its direction — and nothing more.
#
# Column D of the G3/G7 Matrix reads verbs as forces applied between nodes
# rather than as grammatical decoration. The thing that makes this hard is
# Freud's: a surface negation can carry the very intent it appears to deny.
# "Nechceš kávu?" — "Don't you want coffee?" — is an offer in Slovak and is
# routinely read as refusal through an English-shaped frame.
#
# So this reads SURFACE polarity only, deterministically, and says so. It never
# claims to know what was meant. Its useful output is not the reading but the
# cases where the reading cannot be trusted: a negative question, a double
# negative, a negated modal. Those are where grammar and intent come apart, and
# naming them is the Sentinel's job — asking whether the conditions for reading
# polarity have been satisfied, rather than reading it anyway.
class ClaimPolarity
  # Standalone negators and contracted forms. Contractions are matched on the
  # suffix so the list does not have to enumerate every auxiliary.
  NEGATORS = %w[
    not never no none nothing nobody nowhere neither nor cannot
  ].freeze
  CONTRACTION = /\w+n[''’]t\b/i

  UNRELIABLE = %i[negative_question double_negation negated_modal].freeze

  # KNOWN LIMITATION — litotes is not detected.
  #
  # "It is not uncommon" reads here as denied, and means roughly the opposite.
  # Catching it would need a rule like "a negator before a word with a negative
  # prefix", and there is no such rule: `understood`, `universe`, `until`,
  # `interesting`, `international` and `information` all carry those prefixes
  # and none of them negates anything. Telling `uncommon` from `understood`
  # requires a lexicon of negative-prefixed words, which is world knowledge —
  # the thing this class exists not to guess at.
  #
  # So it is recorded as a miss rather than papered over with a rule that
  # misfires on "not understood". A spec pins the miss so it stays visible.

  # Modals already hedge the force of a verb; negating one compounds the hedge
  # and the result rarely means the plain opposite.
  MODALS = %w[must should could would might may can will shall ought].freeze

  Reading = Data.define(:surface, :negators, :interrogative, :unreliable) do
    def asserted? = surface == :asserted
    def denied? = surface == :denied
    def questioned? = interrogative

    # The whole point: this is grammar, never intent.
    def surface_only? = true
    def reliable? = unreliable.empty?
    def reason = unreliable.map { it.to_s.humanize.downcase }.to_sentence.presence
  end

  def self.for(text) = new(text).call

  def initialize(text)
    @text = text.to_s
  end

  def call
    Reading.new(surface: surface, negators: negators, interrogative: interrogative?,
                unreliable: unreliable)
  end

  private

  attr_reader :text

  def words = @words ||= text.downcase.scan(/[\w''’-]+/)

  def negators
    @negators ||= words.select { NEGATORS.include?(it) || it.match?(CONTRACTION) }
  end

  def interrogative? = text.strip.end_with?("?")

  def surface
    return :questioned if interrogative?

    negators.size.odd? ? :denied : :asserted
  end

  # Where surface grammar is known to come apart from what was meant. Each of
  # these is a construction, not a guess about content.
  def unreliable
    found = []
    found << :negative_question if interrogative? && negators.any?
    found << :double_negation if negators.size > 1
    found << :negated_modal if negated_modal?
    found
  end

  # "should not" / "cannot" / "won't" — a modal within two words of a negator.
  def negated_modal?
    words.each_with_index.any? do |word, index|
      next false unless MODALS.include?(word) || word == "cannot"
      next true if word == "cannot"

      words[(index + 1)..(index + 2)].to_a.any? { NEGATORS.include?(it) || it.match?(CONTRACTION) }
    end
  end
end
