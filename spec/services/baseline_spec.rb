require "rails_helper"

# A measurement OF the system is a claim like any other: attributable,
# supersedable, and comparable only against a measurement that asked the same
# question under the same conditions.
RSpec.describe Baseline do
  before { seed_quietly }

  let(:model) { LlmModel.find_by!(model_identifier: "gemini-2.5-pro") }
  let(:other) { LlmModel.find_by!(model_identifier: "claude-opus-5") }

  def record(version, criterion: "polarity invariance", rate: 0.85, model: self.model, **overrides)
    described_class.record!(
      version: version, criterion: criterion, model: model,
      measured: { rate: rate }, sample: { claims: 20 },
      conditions: { batch_size: 12, context_claims: 4 }.merge(overrides.fetch(:conditions, {})),
      caveats: overrides[:caveats], detail: overrides[:detail]
    )
  end

  it "records the measurement as a claim about the model" do
    measurement = record("v1")

    expect(measurement.assertion.subject).to eq model
    expect(measurement.assertion.asserter.key).to eq "baseline-recorder"
    expect(measurement.rate).to eq 0.85
  end

  # Without this a changed rate cannot be told apart from a changed instrument.
  it "records the code revision that produced it" do
    expect(record("v1").code_sha).to be_present
  end

  it "keeps the sample and the conditions, not just the number" do
    measurement = record("v1")

    expect(measurement.sample["claims"]).to eq 20
    expect(measurement.conditions["batch_size"]).to eq 12
  end

  it "keeps the caveats, because a baseline without its limits gets misused" do
    measurement = record("v1", caveats: [ "one scenario per tension" ])

    expect(measurement.caveats).to eq [ "one scenario per tension" ]
  end

  it "scopes to a version and a model" do
    record("v1")
    record("v2")
    record("v1", model: other)

    expect(described_class.for(version: "v1", model: model).size).to eq 1
    expect(described_class.for(version: "v1").size).to eq 2
  end

  # Superseded rather than overwritten: the earlier reading is still there.
  it "reports only the standing measurement when one supersedes another" do
    first = record("v1", rate: 0.70)
    Assertion.create!(asserter: described_class.recorder, subject: model, act: "assert",
                      supersedes: first.assertion,
                      claim: { "baseline" => "v1", "criterion" => "polarity invariance",
                               "measured" => { "rate" => 0.86 } })

    standing = described_class.for(version: "v1", model: model)

    expect(standing.map(&:rate)).to eq [ 0.86 ]
    expect(Assertion.where(asserter: described_class.recorder).count).to eq 2
  end

  describe "comparing two baselines" do
    it "reports the delta when the conditions match" do
      record("v1", rate: 0.80)
      record("v2", rate: 0.88)

      row = described_class.compare(from: "v1", to: "v2", model: model).sole

      expect(row[:delta]).to eq 0.08
      expect(row[:comparable]).to be true
      expect(row[:note]).to be_nil
    end

    # The numbers are not answering the same question, and saying so is the
    # whole point of keeping the conditions.
    it "refuses to call it comparable when the conditions differ" do
      record("v1", rate: 0.65, conditions: { batch_size: 1, context_claims: 0 })
      record("v2", rate: 0.88)

      row = described_class.compare(from: "v1", to: "v2", model: model).sole

      expect(row[:comparable]).to be false
      expect(row[:note]).to include "conditions differ"
      expect(row[:note]).to include "batch_size"
    end

    # A measurement that was not repeated is not a measurement that agreed.
    it "reports a criterion missing from the later baseline rather than dropping it" do
      record("v1", criterion: "order stability")
      record("v2", criterion: "polarity invariance")

      rows = described_class.compare(from: "v1", to: "v2", model: model)

      expect(rows.map { it[:criterion] }).to contain_exactly("order stability", "polarity invariance")
      expect(rows.find { it[:criterion] == "order stability" }[:note])
        .to eq "not measured in the later baseline"
      expect(rows.find { it[:criterion] == "polarity invariance" }[:note])
        .to eq "not measured in the earlier baseline"
    end

    it "gives no delta when either side has no rate" do
      record("v1", rate: nil)
      record("v2", rate: 0.88)

      expect(described_class.compare(from: "v1", to: "v2", model: model).sole[:delta]).to be_nil
    end
  end

  describe "the recorded v1" do
    it "is readable back with everything needed to repeat it" do
      measurement = record("v1", caveats: [ "c" ])

      expect(measurement.criterion).to be_present
      expect(measurement.version).to eq "v1"
      expect(measurement.recorded_at).to be_present
      expect(measurement.model).to eq model
    end
  end
end
