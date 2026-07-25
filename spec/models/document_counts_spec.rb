require "rails_helper"

# The progress report is only worth having if its numbers are the same numbers
# the record would give. A fast count that drifts from the slow one is worse
# than no count at all.
RSpec.describe "counting classified claims" do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:document) { Document.create!(body: "…") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:system) do
    Referent.create!(key: "claim-classifier", name: "Claim Classifier", subject: "System",
                     role: "Classifier", primitive: "system")
  end
  let(:observation) do
    ClaimCategory.create!(framework: framework, key: "observation", name: "Observation",
                          position: 1, justification_rank: 1, definition: "…", confidence_source: "…")
  end
  let(:interpretive) do
    ClaimCategory.create!(framework: framework, key: "interpretive", name: "Interpretive",
                          position: 2, justification_rank: 2, definition: "…", confidence_source: "…")
  end

  def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

  def slow_count = document.claims.count - document.unclassified_claims.count

  it "agrees with deriving each category, one claim at a time" do
    a = claim("one")
    claim("two")
    c = claim("three")
    a.classify!(observation, asserter: system, confidence: 0.9)
    c.classify!(interpretive, asserter: person, confidence: 1.0)

    expect(document.classified_claims_count).to eq 2
    expect(document.classified_claims_count).to eq slow_count
    expect(document.unclassified_claims_count).to eq 1
  end

  it "counts a claim once even when a person overrode the system" do
    a = claim("one")
    first = a.classify!(observation, asserter: system, confidence: 0.9)
    a.classify!(interpretive, asserter: person, confidence: 1.0, supersedes: first)

    expect(document.classified_claims_count).to eq 1
    expect(document.classified_claims_count).to eq slow_count
  end

  # Withdrawn with nothing put in its place: the claim goes back to unclassified,
  # and both counts have to agree that it did.
  it "does not count a claim whose only classification was revoked" do
    a = claim("one")
    first = a.classify!(observation, asserter: system, confidence: 0.9)
    claim("two").classify!(observation, asserter: system, confidence: 0.9)

    a.assertions.create!(asserter: person, act: "revoke", supersedes: first)

    expect(a.reload.category).to be_nil
    expect(document.classified_claims_count).to eq 1
    expect(document.classified_claims_count).to eq slow_count
  end

  it "does not count claims belonging to another document" do
    other = Document.create!(body: "elsewhere")
    other.claims.create!(position: 1, text: "theirs")
        .classify!(observation, asserter: system, confidence: 0.9)
    claim("mine")

    expect(document.classified_claims_count).to eq 0
  end

  it "costs a fixed number of queries regardless of how many claims there are" do
    10.times { |i| claim("claim #{i}").classify!(observation, asserter: system, confidence: 0.9) }

    queries = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") { queries += 1 }
    document.classified_claims_count
    ActiveSupport::Notifications.unsubscribe(subscription)

    expect(queries).to be <= 3
  end
end
