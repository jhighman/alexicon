require "rails_helper"

RSpec.describe DocumentClassification do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:document)  { Document.create!(body: "…") }
  let!(:classifier_referent) do
    Referent.create!(key: "claim-classifier", name: "Claim Classifier", subject: "System",
                     role: "Classifier", primitive: "system")
  end
  let(:ontological) do
    ClaimCategory.create!(framework: framework, key: "ontological", name: "Ontological",
                          position: 1, justification_rank: 3, definition: "…", confidence_source: "…")
  end

  def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

  # A classifier double: `outcomes` is consumed one per claim. nil means abstain.
  def classifier_returning(*outcomes)
    queue = outcomes.dup
    category = ontological
    referent = classifier_referent
    Class.new do
      define_method(:initialize) { |claim| @claim = claim }
      define_method(:classify!) do
        queue.shift ? @claim.classify!(category, asserter: referent, confidence: 0.9) : nil
      end
    end
  end

  it "classifies each claim and records what it did" do
    claim("one")
    claim("two")

    result = described_class.call(document, classifier: classifier_returning(true, true))

    expect(result.classified).to eq 2
    expect(result.abstained).to eq 0
    expect(document.classified?).to be true
  end

  # An abstention is the absence of a judgement. Counting it is honest;
  # recording it as a classification would invent the judgement it declined.
  it "counts abstentions without recording them as classifications" do
    claim("one")
    claim("two")

    result = described_class.call(document, classifier: classifier_returning(true, nil))

    expect(result.classified).to eq 1
    expect(result.abstained).to eq 1
    expect(document.unclassified_claims.count).to eq 1
    expect(Assertion.acting("classify").count).to eq 1
  end

  it "records the run as an attributable assertion" do
    claim("one")

    described_class.call(document, classifier: classifier_returning(true))

    run = document.last_classification_run
    expect(run.asserter).to eq classifier_referent
    expect(run.claim).to include("run" => "classification", "classified" => 1, "abstained" => 0)
  end

  # A standing classification is answered or superseded deliberately, never
  # overwritten by a second pass.
  it "does not reclassify a claim that already has a category" do
    c = claim("one")
    c.classify!(ontological, asserter: classifier_referent)

    result = described_class.call(document, classifier: classifier_returning(true))

    expect(result.skipped).to eq 1
    expect(result.classified).to eq 0
    expect(c.classifications.count).to eq 1
  end

  # Typing a statement does not predicate anything of the names inside it, so
  # an unresolved name is not grounds for refusing to read the document. What
  # stays blocked is judging the steps between its claims.
  it "runs while identity is unresolved" do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
    c = claim("Pugsley left.")
    IdentitySentinel.verify!(c.mentions.create!(text: "Pugsley"))

    result = described_class.call(document, classifier: classifier_returning(true))

    expect(result.classified).to eq 1
    expect(document.open_stops).to be_present
    expect { document.require_executable! }.to raise_error(Document::ExecutionLocked)
  end
end
