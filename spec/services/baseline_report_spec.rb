require "rails_helper"

# The document is derived so it cannot lag behind the measurements. These specs
# guard the property that made it worth deriving: everything recorded appears,
# and nothing appears that was not recorded.
RSpec.describe BaselineReport do
  before { seed_quietly }

  let(:model) { LlmModel.find_by!(model_identifier: "claude-opus-5") }

  def record(criterion:, **attrs)
    Baseline.record!(**{ version: "test", criterion: criterion, model: model,
                         measured: { rate: 0.9, checked: 10 }, sample: {}, conditions: {} }
                       .merge(attrs))
  end

  it "says so plainly when nothing has been measured" do
    expect(described_class.render(version: "empty")).to include "No measurements recorded"
  end

  it "renders every recorded measurement, numbered" do
    record(criterion: "one")
    record(criterion: "two")

    report = described_class.render(version: "test")

    expect(report).to include "## 1. One", "## 2. Two"
  end

  # The drift that prompted this: the file said seven, the system held eight.
  it "counts what is there rather than what was written down" do
    3.times { record(criterion: "criterion #{it}") }

    expect(described_class.render(version: "test")).to include "**Correctness.** 3 figures"
  end

  it "shows a nested figure rather than dropping it" do
    record(criterion: "moves", measured: { rate: 0.5, top_moves: { "a->b" => 4 } })

    expect(described_class.render(version: "test")).to include "| top moves — a->b | 4 |"
  end

  # A recorded field the document drops is the drift this generator exists to stop.
  it "shows the detail the measurement was recorded with" do
    record(criterion: "one", detail: "the comparison the earlier figure could not make")

    expect(described_class.render(version: "test"))
      .to include "the comparison the earlier figure could not make"
  end

  it "renders a detail recorded as named fields rather than printing a hash at the reader" do
    record(criterion: "one", detail: { note: "20 pairs; per-pair categories in the run log" })

    report = described_class.render(version: "test")

    expect(report).to include "| note | 20 pairs; per-pair categories in the run log |"
    expect(report).not_to include "=>"
  end

  it "carries the caveats through, since a figure without them overstates itself" do
    record(criterion: "one", caveats: [ "classified alone, not in context" ])

    report = described_class.render(version: "test")

    expect(report).to include "What this cannot tell you", "classified alone, not in context"
  end

  it "states the sample and conditions a figure was taken under" do
    record(criterion: "one", sample: { claims: 20 }, conditions: { batch_size: 12 })

    report = described_class.render(version: "test")

    expect(report).to include "**Sample:** claims 20", "**Conditions:** batch size 12"
  end

  # Measurements taken at different revisions are not one baseline, and a header
  # naming a single SHA would say they were.
  describe "code revisions" do
    it "names the revision when every figure shares one" do
      record(criterion: "one", code_sha: "abc1234")
      record(criterion: "two", code_sha: "abc1234")

      expect(described_class.render(version: "test")).to include "Taken at code `abc1234`"
    end

    it "warns when the figures were taken across more than one" do
      record(criterion: "one", code_sha: "abc1234")
      record(criterion: "two", code_sha: "def5678")

      report = described_class.render(version: "test")

      expect(report).to include "Taken across 2 code revisions", "`abc1234`, `def5678`"
      expect(report).to include "may be a difference in the code"
    end
  end

  it "renders a criterion it has no editorial note for" do
    record(criterion: "something measured after this file was written")

    report = described_class.render(version: "test")

    expect(report).to include "## 1. Something measured after this file was written"
    expect(report).to include "| rate | 90.0% |"
  end

  # The headings are the part that drifted. Editorial picks which figure leads;
  # the figure itself always comes from the measurement.
  describe "a heading for a measurement with several figures" do
    let(:criterion) { "context effect on classification" }

    it "substitutes the recorded numbers into the authored wording" do
      record(criterion: criterion,
             measured: { single_claim_agreement: 0.65, batched_agreement: 0.88 })

      expect(described_class.render(version: "test"))
        .to include "## 1. Context effect on classification — 65.0% alone → 88.0% in context"
    end

    it "reads a figure out of a nested group" do
      record(criterion: "reproducibility by category pair",
             measured: { interpretive_ontological: { rate: 0.8 },
                         objective_observation: { rate: 0.9 } })

      expect(described_class.render(version: "test"))
        .to include "— 80.0% on the central distinction, 90.0% elsewhere"
    end

    # A heading with a hole in it is worse than a heading with nothing in it.
    it "drops the heading rather than half-filling it when a figure is missing" do
      record(criterion: criterion, measured: { batched_agreement: 0.88 })

      report = described_class.render(version: "test")

      expect(report).to include "## 1. Context effect on classification\n"
      expect(report).not_to include "alone →"
    end
  end

  it "leads with the rate when there is one, and does not invent one otherwise" do
    record(criterion: "one")
    record(criterion: "two", measured: { agreed: 4 })

    report = described_class.render(version: "test")

    expect(report).to include "## 1. One — 90.0%"
    expect(report).to include "## 2. Two\n"
  end
end
