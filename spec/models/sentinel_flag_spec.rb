require "rails_helper"

# A flag never asserts that a claim is false. It asserts that a category
# changed without a corresponding increase in justification -- and the author
# keeps the right to reject it.
RSpec.describe SentinelFlag do
  let(:document) { Document.create!(body: "…") }
  let(:transition) do
    a = document.claims.create!(position: 1, text: "one")
    b = document.claims.create!(position: 2, text: "two")
    Transition.create!(source: a, target: b)
  end

  it "opens undisposed" do
    flag = transition.sentinel_flags.create!(message: "…")

    expect(flag.disposition).to eq "open"
    expect(flag.disposed_at).to be_nil
  end

  it "records who disposed of it and when, preserving the flag" do
    flag = transition.sentinel_flags.create!(message: "…")

    flag.dispose!(as: "rejected", by: "jeff")

    expect(flag.disposition).to eq "rejected"
    expect(flag.disposed_by).to eq "jeff"
    expect(flag.disposed_at).to be_present
    expect(flag.message).to be_present
  end

  it "refuses an unknown disposition" do
    flag = transition.sentinel_flags.create!(message: "…")

    expect { flag.dispose!(as: "ignored") }.to raise_error(ArgumentError)
  end

  it "treats a stop as a severity, not an error state" do
    flag = transition.sentinel_flags.create!(message: "…", severity: "stop")

    expect(flag).to be_stop
    expect(described_class.stopping).to include(flag)
  end
end
