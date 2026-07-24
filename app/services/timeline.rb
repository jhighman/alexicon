# A referent's record, reconstructed from fixed anchors.
#
# The Double Vector Bypass in one idea: do not read a life off the surface
# shape of a document. Read it from dated, evidenced assertions, and treat the
# spaces between them as spaces — not as findings.
#
# A gap here is a period during which nothing was asserted. That is all it is.
# It is not unemployment, not decline, not concealment; it is the absence of a
# claim, and this class deliberately offers no method that scores it.
class Timeline
  Span = Data.define(:from, :to, :relationship, :kind)
  Gap  = Data.define(:from, :to) do
    def days = ((to - from) / 1.day).round
  end

  def initialize(referent)
    @referent = referent
  end

  # Every period an established relationship covers, oldest first. Only
  # standing assert/amend assertions with a start date count -- an undated
  # claim anchors nothing.
  def spans
    @spans ||= referent.relationships.flat_map { |relationship|
      relationship.standing_assertions
                  .select { it.act.in?(Relationship::ESTABLISHING) && it.valid_from.present? }
                  .map do |assertion|
                    Span.new(from: assertion.valid_from, to: assertion.valid_until,
                             relationship: relationship, kind: relationship.kind)
                  end
    }.sort_by(&:from)
  end

  # Periods between one span ending and the next beginning. Reported because a
  # reviewer may want to ask about them -- never because they are evidence.
  def gaps
    closed = spans.reject { it.to.nil? }.sort_by(&:from)
    return [] if closed.size < 2

    closed.each_cons(2).filter_map do |earlier, later|
      Gap.new(from: earlier.to, to: later.from) if later.from > earlier.to
    end
  end

  # The fixed points a timeline is reconstructed from: dated assertions backed
  # by evidence. These are what a record is read from, rather than its
  # apparent continuity.
  def anchors
    referent.relationships.flat_map { |relationship|
      relationship.standing_assertions.select { it.valid_from.present? && it.evidence.any? }
    }.sort_by(&:valid_from)
  end

  def established_kinds = spans.map(&:kind).uniq.sort

  def evidenced_spans = spans.count { it.relationship.evidence.any? }

  private

  attr_reader :referent
end
