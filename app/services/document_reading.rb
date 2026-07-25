# The document as a person would read it, with the system's judgements attached.
#
# The review surface showed a parts bin: 244 claim rows beside 243 step rows,
# which is the working memory of the analysis rather than anything anyone reads.
# A reader wants the text, and wants to be told where its reasoning outran its
# justification -- in the margin, next to the sentence it is about.
#
# Nothing here generates prose. The narrative is the one that was written; the
# judgements hang off it. A model retelling the document in its own words would
# read as more authoritative than the record while being less accountable than
# it -- fluency mistaken for grounding, which is the failure this project is
# named after.
class DocumentReading
  # A run of the original text. `claim` is present when the run is one, so the
  # gaps between claims -- headings, blank lines, punctuation the segmenter did
  # not take -- survive rather than being silently dropped.
  Segment = Data.define(:text, :claim) do
    def claim? = claim.present?
  end

  Finding = Data.define(:kind, :message, :subject) do
    def unearned? = kind == :unearned
  end

  def self.for(document) = new(document)

  def initialize(document)
    @document = document
  end

  # The text in order, claims interleaved with what lies between them.
  def segments
    @segments ||= build_segments
  end

  # What the reader should know before starting, so they know where to look.
  def summary
    {
      claims: claims.size,
      classified: claims.count(&:category),
      categories: claims.filter_map { it.category&.name }.tally.sort_by { -it.last },
      unearned: unearned_steps.size,
      steps_judged: transitions.count { it.verdict != "undetermined" },
      steps: transitions.size,
      open_names: document.unresolved_name_count
    }
  end

  # Findings anchored to the claim they concern, so the view can put them in the
  # margin beside it rather than in a table somewhere else.
  def findings_for(claim)
    findings[claim.id] || []
  end

  def unearned_steps = @unearned_steps ||= transitions.select(&:unearned?)

  private

  attr_reader :document

  def claims = @claims ||= document.claims.includes(:mentions).to_a

  def transitions
    @transitions ||= document.transitions.includes(:source, :target).to_a
  end

  # A step is reported on the claim it lands on: that is the sentence where the
  # promotion happened, and the one a reader is looking at when they want to know
  # whether it was earned.
  def findings
    @findings ||= begin
      map = Hash.new { |h, k| h[k] = [] }

      unearned_steps.each do |step|
        next if step.to_claim.nil?

        map[step.to_claim.id] << Finding.new(
          kind: :unearned,
          subject: step,
          message: "This step was judged unearned: #{step.from_claim&.category&.name.to_s.downcase} " \
                   "to #{step.to_claim.category&.name.to_s.downcase} without the justification that requires."
        )
      end

      document.flags.select(&:open?).each do |flag|
        claim = anchor_claim_for(flag)
        next if claim.nil?

        map[claim.id] << Finding.new(kind: :flag, subject: flag, message: flag.message)
      end

      map
    end
  end

  def anchor_claim_for(flag)
    case flag.subject
    when Claim then flag.subject
    when Mention then flag.subject.claim
    when Transition then flag.subject.to_claim
    end
  end

  # Slices the body on claim offsets. Anything not covered by a claim is kept as
  # a gap: dropping it would quietly rewrite the document into the parts the
  # segmenter happened to recognise.
  def build_segments
    body = document.body.to_s
    ordered = claims.select { it.char_start && it.char_end }.sort_by(&:char_start)

    cursor = 0
    out = []

    ordered.each do |claim|
      next if claim.char_start < cursor

      out << Segment.new(text: body[cursor...claim.char_start], claim: nil) if claim.char_start > cursor
      out << Segment.new(text: body[claim.char_start...claim.char_end], claim: claim)
      cursor = claim.char_end
    end

    out << Segment.new(text: body[cursor..], claim: nil) if cursor < body.length

    # Blank gaps are kept. They are the paragraph breaks: dropping them because
    # they contain no words collapses an essay into one wall of text, which is
    # the readability problem this view exists to fix.
    out.reject { it.text.to_s.empty? }
  end
end
