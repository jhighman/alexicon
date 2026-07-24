require "rails_helper"

RSpec.describe "LLM governance" do
  let(:person) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let(:classifier) do
    Referent.create!(key: "claim-classifier", name: "Claim Classifier", subject: "System",
                     role: "Classifier", primitive: "system")
  end
  let(:provider) { LlmProvider.create!(key: "anthropic", name: "Anthropic") }

  def model(identifier: "claude-opus-5", **)
    LlmModel.create!(llm_provider: provider, model_identifier: identifier,
                     display_name: identifier, cost_per_1k_input: 0.005,
                     cost_per_1k_output: 0.025, **)
  end

  describe LlmModel do
    # A model does not get to influence a judgement because it exists, but
    # because someone accountable said it may.
    it "is not assignable until certified" do
      m = model

      expect(m).not_to be_certified
      expect(LlmModel.assignable).to be_empty

      m.certify!(person)

      expect(LlmModel.assignable).to contain_exactly(m)
      expect(m.certified_by).to eq person
      expect(m.certified_at).to be_present
    end

    # "Certified" with nobody's name on it is the same as uncertified.
    it "refuses certification with no author" do
      m = model
      m.certification_status = "certified"

      expect(m).not_to be_valid
      expect(m.errors[:certified_by].join).to include "somebody's decision"
    end

    it "records why a model was withdrawn" do
      m = model
      m.certify!(person)

      m.revoke!(reason: "produced unattributable output", by: person)

      expect(m).to be_revoked
      expect(m.revocation_reason).to include "unattributable"
      expect(LlmModel.assignable).to be_empty
    end

    # Re-certifying under the same identity would erase why it was withdrawn.
    it "will not re-certify a revoked model" do
      m = model
      m.certify!(person)
      m.revoke!(reason: "…")

      expect { m.certify!(person) }.to raise_error(ArgumentError, /revoked/)
    end

    it "prices a call from its own published rates" do
      expect(model.cost_for(input_tokens: 1000, output_tokens: 1000)).to eq 0.03
    end
  end

  describe LlmAssignment do
    it "cannot point at an uncertified model" do
      assignment = LlmAssignment.new(llm_model: model, agent_pattern: "claim-classifier")

      expect(assignment).not_to be_valid
      expect(assignment.errors[:llm_model].join).to include "certified"
    end

    it "matches a caller by glob" do
      m = model
      m.certify!(person)
      assignment = LlmAssignment.create!(llm_model: m, agent_pattern: "*-sentinel")

      expect(assignment.matches?(agent_key: "identity-sentinel", action_type: "classify")).to be true
      expect(assignment.matches?(agent_key: "claim-classifier", action_type: "classify")).to be false
    end

    it "scores an exact caller and a named action as more specific" do
      m = model
      m.certify!(person)
      broad = LlmAssignment.create!(llm_model: m, agent_pattern: "*")
      narrow = LlmAssignment.create!(llm_model: m, agent_pattern: "claim-classifier",
                                     action_type: "classify")

      expect(narrow.specificity).to be > broad.specificity
    end
  end

  describe LlmResolver do
    def certified_model = model.tap { it.certify!(person) }

    it "says so when no model has been certified" do
      model # registered, not certified
      result = described_class.resolve(agent: classifier, action_type: "classify")

      expect(result).not_to be_resolved
      expect(result.error).to include "certified by a named person"
    end

    it "resolves through a matching assignment" do
      m = certified_model
      assignment = LlmAssignment.create!(llm_model: m, agent_pattern: "claim-classifier",
                                         action_type: "classify")

      result = described_class.resolve(agent: classifier, action_type: "classify")

      expect(result).to be_resolved
      expect(result.model).to eq m
      expect(result.assignment).to eq assignment
    end

    # Specificity decides before priority, so a broad rule with a big number
    # cannot capture traffic a narrow rule was written for.
    it "prefers the more specific rule over the higher priority one" do
      m = certified_model
      other = model(identifier: "claude-sonnet-5").tap { it.certify!(person) }
      LlmAssignment.create!(llm_model: other, agent_pattern: "*", priority: 100)
      narrow = LlmAssignment.create!(llm_model: m, agent_pattern: "claim-classifier",
                                     action_type: "classify", priority: 0)

      expect(described_class.resolve(agent: classifier, action_type: "classify").assignment)
        .to eq narrow
    end

    # A fallback would run a call on a model nobody chose for it.
    it "refuses rather than falling back when nothing matches" do
      certified_model
      LlmAssignment.create!(llm_model: LlmModel.first, agent_pattern: "identity-sentinel")

      result = described_class.resolve(agent: classifier, action_type: "classify")

      expect(result).not_to be_resolved
      expect(result.error).to include "no assignment matches"
    end

    it "ignores an inactive assignment" do
      m = certified_model
      LlmAssignment.create!(llm_model: m, agent_pattern: "claim-classifier", active: false)

      expect(described_class.resolve(agent: classifier, action_type: "classify")).not_to be_resolved
    end
  end

  describe LlmInvocation do
    def invocation(**)
      m = model.tap { it.certify!(person) }
      LlmInvocation.create!(llm_model: m, agent: classifier, status: "success",
                            input_tokens: 1000, output_tokens: 1000, **)
    end

    it "prices and totals itself from the model's rates" do
      call = invocation

      expect(call.total_tokens).to eq 2000
      expect(call.cost_usd).to eq 0.03
    end

    # An invocation records what happened, and what happened does not change.
    it "is immutable" do
      call = invocation

      expect(call).to be_readonly
      expect { call.update!(status: "error") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    # Without failures recorded, "never asked" and "asked and broke" look alike.
    it "records failures too" do
      call = invocation(status: "error", error_message: "connection reset")

      expect(LlmInvocation.failed).to include call
      expect(LlmInvocation.success_rate).to eq 0.0
    end
  end
end
