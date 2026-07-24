# Text in, governed graph out.
#
#   segment   -- the body becomes claims, by offset, without modifying it
#   extract   -- each claim proposes candidate identifiers
#   verify    -- the Identity Sentinel disposes of each candidate
#   connect   -- adjacent claims are joined by transitions
#
# What ingest deliberately does NOT do is judge. It creates the transitions but
# records no verdict on them; it classifies nothing. Chapter 6 requires the
# evaluator to be independent of the transformation it governs, so the thing
# that builds the graph must not also rule on it. Ingest leaves every
# transition `proposed` and every claim unclassified, for a sentinel that did
# not construct them.
#
# Identity is verified during ingest because it precedes reasoning: a document
# whose subjects are ungrounded is locked before anything can be classified.
class DocumentIngest
  Result = Data.define(:document, :claims, :mentions, :transitions) do
    def blocked? = document.executable? == false
  end

  class AlreadyIngested < StandardError; end

  def self.call(document) = new(document).call

  def self.ingest!(body:, title: nil, source_kind: "pasted")
    call(Document.create!(body: body, title: title, source_kind: source_kind))
  end

  def initialize(document)
    @document = document
  end

  def call
    raise AlreadyIngested, "document #{document.id} already has claims" if document.claims.exists?

    claims = segment
    mentions = claims.flat_map { extract_from(it) }
    transitions = connect(claims)

    # Verification runs after the graph exists, so a Sentinel judgement always
    # has a complete subject to attach to.
    mentions.each { IdentitySentinel.verify!(it) }

    Result.new(document: document, claims: claims, mentions: mentions, transitions: transitions)
  end

  private

  attr_reader :document

  def segment
    ClaimSegmenter.new(document.body).call.each_with_index.map do |segment, index|
      document.claims.create!(
        position: index + 1,
        text: segment.text,
        char_start: segment.char_start,
        char_end: segment.char_end
      )
    end
  end

  def extract_from(claim)
    MentionExtractor.new(claim).call.map do |candidate|
      claim.mentions.create!(
        text: candidate.text,
        char_start: candidate.char_start,
        char_end: candidate.char_end
      )
    end
  end

  # Adjacency only. Real arguments branch, and a transition may be created
  # between any two claims later; this is the default reading order, not a
  # claim about the argument's structure.
  def connect(claims)
    claims.each_cons(2).map { |from, to| Transition.create!(source: from, target: to) }
  end
end
