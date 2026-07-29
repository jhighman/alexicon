# Finds candidate identifiers in a claim.
#
# This is a transformation, not an answer. Chapter 7.6 names "names become
# entities" as a binding requiring governance, and that is exactly the split
# here: the extractor PROPOSES candidates, the Identity Sentinel DISPOSES of
# them. Extraction never decides what a name refers to, and never decides that
# an unrecognised name is not a name.
#
# Two sources, deliberately:
#
#   known    -- surface forms of referents already in the graph, matched
#               wherever they appear, in any case
#   candidate -- capitalised token sequences, which is how an unfamiliar name
#               gets noticed at all
#
# Without the second, an unknown name would never be extracted and so never
# flagged out-of-distribution -- the system would silently reason past every
# subject it had never met. That is the failure the Sentinel exists to catch,
# so the extractor errs toward proposing too much and lets the Sentinel refuse.
#
# The capitalisation heuristic is the weakest link in the pipeline and is
# labelled as such. A proper named-entity model would be an improvement, and
# would itself be a transformation requiring its own governance.
class MentionExtractor
  Candidate = Data.define(:text, :char_start, :char_end)

  # Spaces and tabs only. With \s+ this crossed line breaks, so a heading ran
  # into the sentence beneath it and arrived as one name: "Michael Polanyi\nOne"
  # was extracted instead of "Michael Polanyi", which meant the real referent
  # could never match. A name does not span a line break.
  CAPITALISED = /\b[A-Z][\p{Alpha}'’-]+(?:[ \t]+[A-Z][\p{Alpha}'’-]+)*/

  # An all-capital token's case is explained by acronym convention, not by
  # proper-nounhood, so it is not evidence on its own. "NMDA" in "NMDA
  # receptors" is a technical term; a known acronym still matches via `known`.
  ACRONYM = /\A[\p{Lu}][\p{Lu}\d]+\z/

  # Capitalised words that are almost never identifiers. Sentence-initial
  # function words and the English first-person pronoun.
  STOPWORDS = %w[
    i a an the this that these those there here it its
    and but or nor so yet for if when while because since although though
    therefore thus hence however moreover furthermore nevertheless otherwise
    he she they we you his her their our your my me him them us
    what which who whom whose why how where whether
    is are was were be been being do does did have has had
    not no yes maybe perhaps suppose consider notice
  ].freeze

  # `casing` is shared across a document's claims when ingesting, so the
  # evidence is gathered once rather than per claim.
  def initialize(claim, casing: nil)
    @claim = claim
    @text = claim.text.to_s
    @origin = claim.char_start || 0
    @casing = casing || CasingEvidence.for(claim.document)
  end

  def call
    (known + capitalised)
      .reject { IgnoredForm.ignores?(it.text) }
      .sort_by { [ it.char_start, -it.text.length ] }
      .then { drop_overlaps(it) }
  end

  private

  attr_reader :claim, :text, :origin, :casing

  # Surface forms already in the graph, matched case-insensitively at any
  # POSITION in the claim -- a known referent should be recognised even in lower
  # case -- but never inside another word.
  #
  # Without that second guard the match was a bare substring, and every short
  # name ever grounded became a landmine in every document written afterwards.
  # A referent named "Eve", grounded once while reading an essay, produced 36
  # mentions in an unrelated letter: whenever, even, eleven, however, believe.
  # Each one raised an identity STOP, and a STOP blocks governance, so a name
  # from one document could halt the analysis of another it never appeared in.
  #
  # Lookarounds rather than \b: a form may begin or end with punctuation --
  # "St. Joe", "O'Brien" -- and \b is defined against word characters, so it
  # behaves differently at those edges depending on the form. Asserting that
  # neither neighbour is alphanumeric says what is actually meant, and still
  # admits a possessive: "McDonald" matches in "McDonald's".
  def known
    forms = Referent.pluck(:name) + ReferentAlias.pluck(:name)
    forms.compact.uniq.flat_map { matches_for(word_pattern(it)) }
  end

  def word_pattern(form)
    Regexp.new("(?<![[:alnum:]])#{Regexp.escape(form)}(?![[:alnum:]])", Regexp::IGNORECASE)
  end

  # A sentence-initial function word is capitalised too, so "Therefore God"
  # arrives as one span. Trim leading stopwords rather than discarding the
  # whole candidate, or every claim beginning with "Therefore" would lose its
  # subject.
  def capitalised
    matches_for(CAPITALISED)
      .filter_map { trim_leading_stopwords(it) }
      .reject { it.text.match?(ACRONYM) }
      .reject { casing.explained_by_position?(it.text) }
  end

  def trim_leading_stopwords(candidate)
    words = []
    candidate.text.scan(/\S+/) { words << [ Regexp.last_match[0], Regexp.last_match.begin(0) ] }

    first = words.index { |word, _| !stopword?(word) }
    return nil if first.nil?
    return trim_possessive(candidate) if first.zero?

    offset = words[first].last
    remainder = candidate.text[offset..]
    trim_possessive(Candidate.new(text: remainder,
                                  char_start: candidate.char_start + offset,
                                  char_end: candidate.char_start + offset + remainder.length))
  end

  # A contraction is its pronoun wearing a suffix: "I'm" is "I", which is
  # already a stopword. Without this every sentence opening with "I've" or
  # "He's" proposed a subject.
  def stopword?(word) = STOPWORDS.include?(word.downcase.split(/['’]/).first.to_s)

  # "Alec's essay" mentions Alec. Left alone, the possessive is a third surface
  # form alongside "Alec" and "Alec’s", so one person becomes three identity
  # questions and none of them matches the referent already in the graph.
  def trim_possessive(candidate)
    stripped = candidate.text.sub(/['’]s\z/, "").sub(/['’]\z/, "")
    return candidate if stripped == candidate.text || stripped.empty?

    Candidate.new(text: stripped, char_start: candidate.char_start,
                  char_end: candidate.char_start + stripped.length)
  end

  def matches_for(pattern)
    found = []
    text.scan(pattern) { found << Regexp.last_match }
    found.map do |match|
      Candidate.new(text: match[0],
                    char_start: origin + match.begin(0),
                    char_end: origin + match.end(0))
    end
  end

  # Longest match wins where spans overlap, so "Wednesday Addams" is not also
  # reported as "Wednesday".
  def drop_overlaps(candidates)
    kept = []
    candidates.each do |candidate|
      next if kept.any? { overlaps?(it, candidate) }

      kept << candidate
    end
    kept
  end

  def overlaps?(kept, candidate)
    candidate.char_start < kept.char_end && kept.char_start < candidate.char_end
  end
end
