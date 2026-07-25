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

  def explained_by_position?(form)
    return false if form.blank?

    @cache.fetch(form) { @cache[form] = lower_case_elsewhere?(form) }
  end

  private

  attr_reader :text

  # The same form, written in lower case, somewhere else in the same document.
  def lower_case_elsewhere?(form)
    text.scan(/\b#{Regexp.escape(form)}\b/i).any? { it == it.downcase && it != form }
  end
end
