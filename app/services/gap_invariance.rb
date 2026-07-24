# The enforceable form of the anti-discrimination policy.
#
#   A gap in a record is an absence of evidence, not evidence of degradation.
#
# Stated as a property a scoring function either has or does not:
#
#   For two records identical in their established, evidenced relationships,
#   the score is the same regardless of how those relationships are spaced in
#   time.
#
# This is a NARROW claim, and deliberately so. It does not say a scorer is
# fair — no scorer is fair in general, and demographic parity, equalised odds
# and calibration are provably not simultaneously satisfiable outside
# degenerate cases. It says one specific penalty is absent, and unlike the
# general claim, this one can be checked.
#
# The check works by construction: take a record, build a variant that adds a
# gap without adding or removing anything established, and compare. A scorer
# that reads continuity will differ. A scorer that reads only what was
# established cannot.
class GapInvariance
  CRITERION = "gap invariance".freeze
  GAP = 18.months

  Result = Data.define(:holds, :baseline, :gapped, :criterion) do
    def holds? = holds
    def violation = holds ? nil : "score changed by #{(gapped - baseline).round(4)} when a gap was introduced"
  end

  # `scorer` is any callable taking a Timeline and returning a number.
  def self.holds_for?(scorer, spans:) = check(scorer, spans: spans).holds?

  def self.check(scorer, spans:)
    baseline = scorer.call(stub_timeline(spans))
    gapped   = scorer.call(stub_timeline(spread(spans)))

    Result.new(holds: baseline == gapped, baseline: baseline, gapped: gapped, criterion: CRITERION)
  end

  # Push each span later than the last, opening dead time between them. The
  # set of established relationships is untouched -- only the spacing moves.
  def self.spread(spans)
    spans.each_with_index.map do |span, index|
      offset = GAP * index
      Timeline::Span.new(from: span.from + offset, to: span.to && span.to + offset,
                         relationship: span.relationship, kind: span.kind)
    end
  end

  # A Timeline whose spans are supplied directly, so the property can be
  # checked without persisting a second, deliberately-gapped person.
  def self.stub_timeline(spans)
    Class.new do
      define_method(:spans) { spans }
      define_method(:established_kinds) { spans.map(&:kind).uniq.sort }
      define_method(:evidenced_spans) { spans.count { it.relationship&.evidence&.any? } }
      define_method(:gaps) do
        closed = spans.reject { it.to.nil? }.sort_by(&:from)
        next [] if closed.size < 2

        closed.each_cons(2).filter_map do |a, b|
          Timeline::Gap.new(from: a.to, to: b.from) if b.from > a.to
        end
      end
    end.new
  end
  private_class_method :stub_timeline, :spread
end
