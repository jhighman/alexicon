require "rails_helper"

# The half of the anti-poisoning pair that TEI inversion does not cover. A
# covert policy does not arrive as one suspicious command; it arrives as a slow
# shift across many defensible ones, which is exactly the shape a check applied
# at grant time cannot see.
RSpec.describe TemporalDriftAudit do
  include ActiveSupport::Testing::TimeHelpers

  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:actor) do
    Referent.create!(key: "review-agent", name: "Review Agent", subject: "System",
                     role: "Reviewer", primitive: "system")
  end

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  # Classifications at a chosen time, so a history can be stated rather than
  # waited for. An assertion is readonly once written — travelling to the moment
  # is the only honest way to date one.
  def classify(key, count, at:, by: actor)
    travel_to(at) do
      count.times do |i|
        claim = document.claims.create!(position: document.claims.maximum(:position).to_i + 1,
                                        text: "Claim #{i}.")
        claim.classify!(category(key), asserter: by, confidence: 0.9)
      end
    end
  end

  describe "when there is not enough to go on" do
    it "refuses to compare rather than reporting no drift" do
      classify("interpretive", 5, at: 2.days.ago)
      classify("interpretive", 40, at: 90.days.ago)

      reading = described_class.for(actor)

      expect(reading).not_to be_comparable
      expect(reading).not_to be_notable
      expect(reading.divergence).to be_nil
      expect(reading.incomparable).to match(/too few to tell a shift from noise/)
    end

    it "refuses when the actor has no history to be compared against" do
      classify("interpretive", 40, at: 2.days.ago)

      expect(described_class.for(actor)).not_to be_comparable
    end

    it "says how many it had, so the reader can see how close it was" do
      classify("interpretive", 19, at: 2.days.ago)
      classify("interpretive", 30, at: 90.days.ago)

      expect(described_class.for(actor).incomparable).to include "19", "30", "20"
    end
  end

  describe "a stable actor" do
    it "reports no material shift when the mix has held" do
      %i[recent earlier].each_with_index do |_, index|
        at = index.zero? ? 2.days.ago : 90.days.ago
        classify("interpretive", 30, at: at)
        classify("observation", 10, at: at)
      end

      reading = described_class.for(actor)

      expect(reading).to be_comparable
      expect(reading).not_to be_notable
      expect(reading.divergence).to eq 0.0
      expect(reading.to_s).to match(/no material shift/)
    end
  end

  describe "an actor whose decisions have moved" do
    before do
      classify("interpretive", 40, at: 90.days.ago)
      classify("ontological", 30, at: 2.days.ago)
      classify("interpretive", 10, at: 2.days.ago)
    end

    it "measures the share of decisions that would have to move to reconcile the periods" do
      reading = described_class.for(actor)

      expect(reading).to be_notable
      expect(reading.divergence).to eq 0.75
    end

    it "names what moved, largest first, with its direction" do
      reading = described_class.for(actor)

      expect(reading.moved.keys.first).to eq "ontological"
      expect(reading.moved["ontological"]).to eq 0.75
      expect(reading.moved["interpretive"]).to eq(-0.75)
      expect(reading.largest_move.first).to eq "ontological"
    end

    it "says it in a sentence a person can act on" do
      expect(described_class.for(actor).to_s)
        .to eq "Review Agent: 75.0% of classify decisions moved — ontological up 75.0 points"
    end

    it "keeps the counts from both periods, so the figure can be checked by hand" do
      reading = described_class.for(actor)

      expect(reading.baseline).to eq({ "interpretive" => 40 })
      expect(reading.recent).to eq({ "interpretive" => 10, "ontological" => 30 })
    end
  end

  # The baseline is the actor's own past. Not a population, not a rule about how
  # a reviewer ought to behave — the same refusal ADR 15 makes for peer groups.
  it "compares an actor only against itself" do
    other = Referent.create!(key: "other-agent", name: "Other", subject: "System",
                             role: "Reviewer", primitive: "system")
    classify("interpretive", 40, at: 90.days.ago)
    classify("interpretive", 40, at: 2.days.ago)
    classify("ontological", 40, at: 2.days.ago, by: other)

    expect(described_class.for(actor).divergence).to eq 0.0
  end

  it "reads only the window it was given" do
    classify("interpretive", 40, at: 100.days.ago)
    classify("ontological", 40, at: 40.days.ago)

    narrow = described_class.for(actor, window: 30.days)
    wide = described_class.for(actor, window: 60.days)

    expect(narrow).not_to be_comparable
    expect(wide.divergence).to eq 1.0
  end

  describe "recording the finding" do
    before do
      classify("interpretive", 40, at: 90.days.ago)
      classify("ontological", 40, at: 2.days.ago)
    end

    it "records it as a claim about the actor" do
      assertion = described_class.new(actor, act: "classify", window: 30.days).record!

      expect(assertion.subject).to eq actor
      expect(assertion.asserter.key).to eq described_class::AUDITOR
      expect(assertion.claim).to include("audit" => "temporal drift", "divergence" => 1.0,
                                         "notable" => true, "comparable" => true)
    end

    # A record of only the alarming readings cannot tell you the quiet ones were
    # ever taken.
    it "records a reading that found nothing, too" do
      calm = Referent.create!(key: "calm-agent", name: "Calm", subject: "System",
                              role: "Reviewer", primitive: "system")
      classify("interpretive", 40, at: 90.days.ago, by: calm)
      classify("interpretive", 40, at: 2.days.ago, by: calm)

      assertion = described_class.new(calm, act: "classify", window: 30.days).record!

      expect(assertion.claim).to include("notable" => false, "divergence" => 0.0)
    end
  end

  it "sweeps every actor that has done the act" do
    other = Referent.create!(key: "other-agent", name: "Other", subject: "System",
                             role: "Reviewer", primitive: "system")
    classify("interpretive", 40, at: 90.days.ago)
    classify("ontological", 40, at: 2.days.ago)
    classify("interpretive", 5, at: 2.days.ago, by: other)

    readings = described_class.sweep

    expect(readings.map { it.actor }).to include actor, other
    expect(readings.find { it.actor == actor }).to be_notable
    expect(readings.find { it.actor == other }).not_to be_comparable
  end

  # Drift is not wrongdoing. The report says what changed; a person says whether
  # it was a problem.
  it "never revokes, blocks or reverses anything" do
    classify("interpretive", 40, at: 90.days.ago)
    classify("ontological", 40, at: 2.days.ago)

    expect { described_class.for(actor) }.not_to change(Assertion, :count)
    expect(described_class::Reading.members).not_to include :verdict
  end
end
