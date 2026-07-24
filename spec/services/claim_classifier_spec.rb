require "rails_helper"

# The classifier proposes; the system records the proposal as an inference.
# The client is injected so these specs never touch the network.
RSpec.describe ClaimClassifier do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:document)  { Document.create!(body: "…") }
  let(:claim)     { document.claims.create!(position: 1, text: "Therefore God exists.") }
  let!(:classifier_referent) do
    Referent.create!(key: "claim-classifier", name: "Claim Classifier", subject: "System",
                     role: "Classifier", primitive: "system")
  end

  let!(:certifier) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let!(:model) do
    provider = LlmProvider.create!(key: "anthropic", name: "Anthropic")
    m = LlmModel.create!(llm_provider: provider, model_identifier: "claude-opus-5",
                         display_name: "Claude Opus 5",
                         cost_per_1k_input: 0.005, cost_per_1k_output: 0.025)
    m.certify!(certifier)
    m
  end
  let!(:assignment) do
    LlmAssignment.create!(llm_model: model, agent_pattern: "claim-classifier",
                          action_type: "classify")
  end

  before do
    [ [ "objective", 1, 1 ], [ "observation", 2, 1 ],
      [ "interpretive", 3, 2 ], [ "ontological", 4, 3 ] ].each do |key, position, rank|
      ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                            position: position, justification_rank: rank,
                            definition: "A #{key} claim.", confidence_source: "Something")
    end
  end

  # Minimal stand-in for the SDK response shape: content is a list of blocks,
  # each with a type and text.
  # An adapter, not a vendor client: the classifier speaks only
  # LlmClients::Base#complete, so the stub is the same shape for every provider.
  def stub_client(payload)
    completion = LlmClients::Completion.new(
      text: payload.is_a?(String) ? payload : payload.to_json,
      input_tokens: 412, output_tokens: 89
    )
    Class.new do
      define_method(:complete) { |**| completion }
    end.new
  end

  def classifier(payload, **)
    described_class.new(claim, client: stub_client(payload), framework: framework, **)
  end

  describe "proposing" do
    it "returns the proposed category, confidence and rationale" do
      proposal = classifier({ category: "ontological", confidence: 0.91,
                              rationale: "asserts what exists" }).call

      expect(proposal.category_key).to eq "ontological"
      expect(proposal.confidence).to eq 0.91
      expect(proposal.rationale).to eq "asserts what exists"
      expect(proposal).not_to be_abstained
    end

    it "records the proposal as an attributable inference" do
      assertion = classifier({ category: "ontological", confidence: 0.91,
                               rationale: "asserts what exists" }).classify!

      expect(assertion.act).to eq "classify"
      expect(assertion.asserter).to eq classifier_referent
      expect(assertion).to be_inferred
      expect(assertion.object.key).to eq "ontological"
      expect(claim.category.key).to eq "ontological"
    end

    it "carries the rationale into the record" do
      assertion = classifier({ category: "observation", confidence: 0.88,
                               rationale: "first-person report" }).classify!

      expect(assertion.rationale).to eq "first-person report"
      expect(assertion.confidence).to eq 0.88
    end
  end

  describe "abstaining" do
    it "records nothing when the model abstains" do
      result = classifier({ category: "uncertain", confidence: 0.4,
                            rationale: "ambiguous" }).classify!

      expect(result).to be_nil
      expect(claim.category).to be_nil
      expect(claim.assertions).to be_empty
    end

    # A prediction is not operational truth until a policy says it is.
    it "discards a confident-looking proposal below the floor" do
      proposal = classifier({ category: "ontological", confidence: 0.5,
                              rationale: "maybe" }).call

      expect(proposal).to be_abstained
      expect(claim.reload.category).to be_nil
    end

    it "honours a caller-supplied floor" do
      strict = classifier({ category: "ontological", confidence: 0.8, rationale: "…" },
                          confidence_floor: 0.9)

      expect(strict.call).to be_abstained
    end

    # The schema constrains the model; the system verifies regardless.
    it "rejects a category outside the seeded taxonomy" do
      proposal = classifier({ category: "metaphysical", confidence: 0.99,
                              rationale: "invented" }).call

      expect(proposal).to be_abstained
      expect(claim.reload.category).to be_nil
    end

    it "fails closed on unparseable output" do
      proposal = classifier("not json at all").call

      expect(proposal).to be_abstained
      expect(proposal.rationale).to include "unparseable"
    end
  end

  describe "independence" do
    # Chapter 6: the evaluator must not be the transformation it governs.
    it "leaves the Governance Sentinel free to rule on the result" do
      governance = Referent.create!(key: "governance-sentinel", name: "Governance Sentinel",
                                    subject: "System", role: "Sentinel", primitive: "system")
      other = document.claims.create!(position: 2, text: "I saw a wall collapse.")
      classifier({ category: "ontological", confidence: 0.9, rationale: "…" }).classify!
      described_class.new(other, client: stub_client({ category: "observation", confidence: 0.9,
                                                       rationale: "…" }),
                          framework: framework).classify!

      transition = Transition.create!(source: other, target: claim)

      expect { GovernanceSentinel.review!(transition) }.not_to raise_error
      expect(transition.verdict).to eq "unearned"
    end
  end

  describe "credentials" do
    it "raises a clear error when no API key is configured" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)

      expect { described_class.new(claim, framework: framework).call }
        .to raise_error(described_class::MissingCredentials, /ANTHROPIC_API_KEY/)
    end
  end
end
