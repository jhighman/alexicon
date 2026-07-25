require "rails_helper"

# Reporting progress is a side channel. It must say true things, and it must
# never be able to affect the run it is describing.
RSpec.describe "classification progress" do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:document)  { Document.create!(body: "…") }
  let!(:classifier_referent) do
    Referent.create!(key: "claim-classifier", name: "Claim Classifier", subject: "System",
                     role: "Classifier", primitive: "system")
  end
  let(:observation) do
    ClaimCategory.create!(framework: framework, key: "observation", name: "Observation",
                          position: 1, justification_rank: 1, definition: "…", confidence_source: "…")
  end

  def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

  def classifier_returning(*outcomes)
    queue = outcomes.dup
    category = observation
    referent = classifier_referent
    Class.new do
      define_method(:initialize) { |claims, **| @claims = Array(claims) }
      define_method(:classify!) do
        @claims.each_with_object({}) do |claim, out|
          out[claim] = queue.shift ? claim.classify!(category, asserter: referent, confidence: 0.9) : nil
        end
      end
    end
  end

  it "reports every claim, in order, with what happened to it" do
    claim("one")
    claim("two")
    seen = []

    DocumentClassification.call(document, classifier: classifier_returning(true, true),
                                          on_progress: ->(claim:, outcome:, index:) {
                                            seen << [ index, claim.position, outcome ]
                                          })

    expect(seen).to eq [ [ 0, 1, :classified ], [ 1, 2, :classified ] ]
  end

  # An abstention is the classifier declining to guess, not a failure.
  it "distinguishes an abstention from a classification" do
    claim("one")
    claim("two")
    outcomes = []

    DocumentClassification.call(document, classifier: classifier_returning(true, false),
                                          on_progress: ->(outcome:, **) { outcomes << outcome })

    expect(outcomes).to eq [ :classified, :abstained ]
  end

  it "reports a claim it skipped rather than passing over it silently" do
    already = claim("one")
    claim("two")
    already.classify!(observation, asserter: classifier_referent, confidence: 1.0)
    outcomes = []

    DocumentClassification.call(document, classifier: classifier_returning(true),
                                          on_progress: ->(outcome:, **) { outcomes << outcome })

    expect(outcomes).to eq [ :skipped, :classified ]
  end

  # Telling someone what is happening must not change what happens.
  it "completes the run even if reporting raises every time" do
    claim("one")
    claim("two")

    result = DocumentClassification.call(document, classifier: classifier_returning(true, true),
                                                   on_progress: ->(**) { raise "socket gone" })

    expect(result.classified).to eq 2
    expect(document.unclassified_claims).to be_empty
  end
end
