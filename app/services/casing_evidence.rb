# Whether a capital letter is evidence of a name.
#
# A capital at the start of a sentence, or on an emphasised abstract noun, is
# explained by position rather than by proper-nounhood. The document usually
# settles the question itself: if "belief" appears in lower case elsewhere in
# the same text, then "Belief" opening a sentence is that same word, not a
# subject the system has never met.
#
# This is deliberately evidence from the document rather than from a
# dictionary. A dictionary answers a different question -- is this a word? --
# and answers it badly for this purpose: it contains "alec" and "wednesday"
# while missing "ketamine" and "nmda", so it would suppress real subjects and
# admit noise. The text in hand is the better witness.
#
# Applied only to capitalisation candidates, never to referents already known
# to the graph. A name someone has grounded stays recognised however it is cased.
class CasingEvidence
  def self.for(document) = new(document&.body)

  def initialize(text)
    @text = text.to_s
    @cache = {}
  end

  # What precedes a capital that explains it: the start of the text, the end of
  # a sentence, or a line break — through any markdown decoration in between,
  # because `**Distinct from` and `> Judgment` are sentence-initial too and the
  # marker is not part of the word.
  SENTENCE_START = /(?:\A|[.!?…]["'”’)\]]*\s|\n)[\s*_>#\-]*\z/

  def explained_by_position?(form)
    return false if form.blank?

    @cache.fetch(form) { @cache[form] = lower_case_elsewhere?(form) }
  end

  # Every capitalised occurrence in the document sits at the start of a
  # sentence, so nothing about this word's case is left for proper-nounhood to
  # explain.
  #
  # This is the test the class is named for and did not perform. Without it,
  # `lower_case_elsewhere?` was the only evidence considered, and a word that
  # never happens to appear in lower case in the same document — "Distinct",
  # opening 29 bolded notes in one appendix and appearing mid-sentence not once —
  # was proposed as a subject 29 times, each proposal raising an identity STOP,
  # and a STOP blocks governance.
  #
  # Deliberately not applied to multi-word candidates. In "Michael Polanyi" the
  # second capital is not explained by position at all, so the evidence is still
  # there and the rule has nothing to say.
  def only_ever_sentence_initial?(form)
    return false if form.blank? || form.include?(" ")

    @initial_cache ||= {}
    @initial_cache.fetch(form) { @initial_cache[form] = every_capital_at_a_sentence_start?(form) }
  end

  private

  attr_reader :text

  # The same form, written in lower case, somewhere else in the same document.
  def lower_case_elsewhere?(form)
    text.scan(/\b#{Regexp.escape(form)}\b/i).any? { it == it.downcase && it != form }
  end

  def every_capital_at_a_sentence_start?(form)
    occurrences = 0
    text.to_enum(:scan, /(?<![[:alnum:]])#{Regexp.escape(form)}(?![[:alnum:]])/).each do
      match = Regexp.last_match
      occurrences += 1
      return false unless text[0...match.begin(0)].match?(SENTENCE_START)
    end

    occurrences.positive?
  end
end
