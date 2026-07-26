require "rails_helper"

# The measure the anti-discrimination policy applies. Sources defined it and
# Equitable Baseline Scoring as containing each other, so it went unbuilt;
# Matrix 2.0 Q4 fixed the direction and Q5 fixed what the ceiling averages over.
#
# Almost every spec here is about the same property: the ceiling must not read
# time. A ceiling that divides by calendar span would reintroduce the exact
# penalty the policy removes, through the denominator, where nobody would look.
RSpec.describe AverageCeilingMetric do
  let(:metric) { described_class.new }

  Evidenced = Struct.new(:evidence)

  def span(from_year, to_year, kind: "employment", evidence: [])
    Timeline::Span.new(from: Time.utc(from_year), to: Time.utc(to_year),
                       relationship: Evidenced.new(evidence), kind: kind)
  end

  # The same shape Timeline presents, built from spans so a record can be stated
  # inline rather than persisted.
  def timeline(*spans)
    Struct.new(:spans) do
      def established_kinds = spans.map(&:kind).uniq.sort
      def evidenced_spans = spans.count { it.relationship&.evidence&.any? }

      def gaps
        spans.sort_by(&:from).each_cons(2).filter_map do |a, b|
          Timeline::Gap.new(from: a.to, to: b.from) if b.from > a.to
        end
      end
    end.new(spans)
  end

  describe "the ceiling" do
    it "is what the record established per window it was active in" do
      reading = metric.read(timeline(span(2000, 2002), span(2002, 2004)))

      expect(reading.ceiling).to eq 1.0
      expect(reading.windows).to eq 2
    end

    it "rises with what a window evidenced, not with how long it ran" do
      bare = metric.ceiling(timeline(span(2000, 2002)))
      evidenced = metric.ceiling(timeline(span(2000, 2002, evidence: [ :a ])))
      longer = metric.ceiling(timeline(span(2000, 2020)))

      expect(evidenced).to be > bare
      expect(longer).to eq bare
    end

    it "is a mean and not a high-water mark, so one strong window cannot define it" do
      mixed = timeline(span(2000, 2002, evidence: [ :a ]), span(2002, 2004))

      expect(metric.ceiling(mixed)).to eq 1.25
    end

    it "reports no ceiling rather than zero-as-a-score for an empty record" do
      reading = metric.read(timeline)

      expect(reading).to be_none
      expect(reading.to_s).to eq "no active window"
    end
  end

  # The property the policy audit certifies, checked here directly.
  describe "gap invariance" do
    let(:spans) { [ span(2000, 2002), span(2002, 2004), span(2004, 2006, kind: "education") ] }

    it "holds: a gap adds no window, so it moves no ceiling" do
      check = GapInvariance.check(metric.to_proc, spans: spans)

      expect(check).to be_holds
      expect(check.baseline).to eq check.gapped
    end

    it "is unmoved by a decade of dead time between the same windows" do
      continuous = timeline(span(2000, 2002), span(2002, 2004))
      interrupted = timeline(span(2000, 2002), span(2014, 2016))

      expect(metric.ceiling(interrupted)).to eq metric.ceiling(continuous)
    end

    # The failure mode this design exists to avoid: dividing by elapsed time.
    it "would have been broken by a ceiling denominated in calendar years" do
      continuous = timeline(span(2000, 2002), span(2002, 2004))
      interrupted = timeline(span(2000, 2002), span(2014, 2016))
      over_calendar = lambda do |t|
        years = (t.spans.map(&:to).max - t.spans.map(&:from).min) / 1.year
        t.spans.size / years
      end

      expect(over_calendar.call(interrupted)).to be < over_calendar.call(continuous)
      expect(metric.ceiling(interrupted)).to eq metric.ceiling(continuous)
    end
  end

  # Where the advantage actually sits: not in the rate, in the number of windows.
  it "separates what a record established per window from how many it had" do
    short = timeline(span(2000, 2002))
    long = timeline(span(2000, 2002), span(2002, 2004), span(2004, 2006))

    expect(metric.ceiling(long)).to eq metric.ceiling(short)
    expect(metric.read(long).windows).to be > metric.read(short).windows
    expect(metric.read(long).total).to be > metric.read(short).total
  end

  describe "a peer group" do
    let(:mine) { timeline(span(2000, 2002, evidence: [ :a ]), span(2002, 2004, evidence: [ :b ])) }

    it "compares demonstrated rates, not the time anyone had" do
      brief_peer = timeline(span(2000, 2001))
      long_peer = timeline(*Array.new(8) { span(2000 + it, 2001 + it) })

      reading = metric.read(mine, peers: [ brief_peer, long_peer ])

      expect(reading).to be_compared
      expect(reading.peer_ceiling).to eq 1.0
      expect(reading.relative).to eq 1.5
    end

    it "stands alone when nobody was supplied, rather than inventing an average" do
      reading = metric.read(mine)

      expect(reading).not_to be_compared
      expect(reading.peer_ceiling).to be_nil
      expect(reading.relative).to be_nil
    end

    it "ignores a peer with no active window instead of scoring them zero" do
      reading = metric.read(mine, peers: [ timeline ])

      expect(reading).not_to be_compared
    end
  end

  describe "what it says about itself" do
    it "states that time was not read" do
      explained = metric.explain(timeline(span(2000, 2002)))

      expect(explained["note"]).to include "never over a population"
      expect(explained["note"]).to match(/Elapsed time, continuity, recency/)
      expect(explained).to include("active_windows" => 1, "peers_supplied" => 0)
    end
  end

  # Matrix 2.0 Q4: the policy invokes the metric, not the other way round.
  describe "invoked by Equitable Baseline Scoring" do
    let(:record) { timeline(span(2000, 2002, evidence: [ :a ]), span(2002, 2004, kind: "education")) }

    it "reports the ceiling alongside the score without changing it" do
      explained = EquitableBaseline.new.explain(record)

      expect(explained["score"]).to eq EquitableBaseline.new.call(record)
      expect(explained["ceiling"]["metric"]).to eq "average ceiling"
      expect(explained["ceiling"]["active_windows"]).to eq 2
    end

    it "hands the policy a reading it can compare between records" do
      reading = EquitableBaseline.new.ceiling(record)

      expect(reading.ceiling).to eq 1.25
      expect(reading.windows).to eq 2
    end
  end
end
