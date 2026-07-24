require "rails_helper"

# "A gap in a record is an absence of evidence, not evidence of degradation."
#
# Stated as a checkable property rather than an aspiration: two records
# identical in what they establish score the same, however they are spaced.
RSpec.describe GapInvariance do
  def spans(*kinds)
    start = 10.years.ago
    kinds.each_with_index.map do |kind, index|
      from = start + (index * 2).years
      Timeline::Span.new(from: from, to: from + 2.years, relationship: nil, kind: kind)
    end
  end

  let(:record) { spans("employment", "education", "licence") }

  describe "a scorer that reads only what was established" do
    it "holds" do
      result = described_class.check(EquitableBaseline.new.to_proc, spans: record)

      expect(result).to be_holds
      expect(result.baseline).to eq result.gapped
      expect(result.violation).to be_nil
    end
  end

  # Without this the check could pass vacuously. A scorer that penalises gaps
  # must be caught, or "the property holds" means nothing.
  describe "a scorer that penalises discontinuity" do
    let(:ideal_based) do
      lambda do |timeline|
        # The thing the policy exists to forbid: measure against an unbroken
        # path and subtract for every departure from it.
        timeline.established_kinds.size - timeline.gaps.sum { it.days / 365.0 }
      end
    end

    it "is caught" do
      result = described_class.check(ideal_based, spans: record)

      expect(result).not_to be_holds
      expect(result.violation).to include "score changed"
    end

    it "reports the size of the penalty it applied" do
      result = described_class.check(ideal_based, spans: record)

      expect(result.gapped).to be < result.baseline
    end
  end

  it "names the criterion it checks, rather than claiming fairness in general" do
    expect(described_class::CRITERION).to eq "gap invariance"
    expect(described_class.check(EquitableBaseline.new.to_proc, spans: record).criterion)
      .to eq "gap invariance"
  end
end

RSpec.describe EquitableBaseline do
  def span(kind, from, to) = Timeline::Span.new(from: from, to: to, relationship: nil, kind: kind)

  let(:timeline) do
    GapInvariance.send(:stub_timeline,
                       [ span("employment", 8.years.ago, 6.years.ago),
                         span("employment", 3.years.ago, 1.year.ago) ])
  end

  it "scores what a record establishes, not how it is spaced" do
    expect(described_class.new.call(timeline)).to eq 1.0
  end

  # The gaps are reported so a reviewer may ask. They are not scored.
  it "reports gaps while contributing nothing for them" do
    explanation = described_class.new.explain(timeline)

    expect(explanation["gaps_observed"]).to eq 1
    expect(explanation["gaps_scored"]).to eq 0
    expect(explanation["note"]).to include "absence of evidence is not evidence of degradation"
  end

  it "states the criterion it satisfies" do
    expect(described_class.new.explain(timeline)["criterion"]).to eq "gap invariance"
  end
end
