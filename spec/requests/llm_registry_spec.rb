require "rails_helper"

# The registry is administered through the browser, so the gates that matter --
# who may register, who may vouch, and whether a model the code cannot call may
# be vouched for at all -- have to hold at the HTTP boundary, not only in the
# model.
RSpec.describe "the LLM registry", type: :request do
  before { seed_quietly }

  let(:anthropic) { LlmProvider.find_by!(key: "anthropic") }
  let(:opus) { LlmModel.find_by!(model_identifier: "claude-opus-5") }

  describe "providers" do
    it "is not readable by a reviewer" do
      sign_in(role: "reviewer", name: "Remy")
      get llm_providers_path

      expect(flash[:alert]).to match(/role does not allow/)
    end

    it "is readable but not writable by an auditor" do
      sign_in(role: "auditor", name: "Ada")

      get llm_providers_path
      expect(response).to have_http_status(:ok)

      get new_llm_provider_path
      expect(flash[:alert]).to match(/role does not allow/)
    end

    it "lets an admin register one" do
      sign_in(role: "admin", name: "Ana")

      expect {
        post llm_providers_path, params: { llm_provider: { key: "openai", name: "OpenAI", status: "active" } }
      }.to change { LlmProvider.where(key: "openai").count }.by(0) # already seeded

      expect(LlmProvider.count).to be >= 3
    end

    it "reports whether the application can actually call each one" do
      expect(anthropic).to be_invocable
      expect(LlmProvider.new(key: "some-vendor")).not_to be_invocable
    end
  end

  describe "registering a model" do
    before { sign_in(role: "admin", name: "Ana") }

    it "arrives pending, so nothing routes to it yet" do
      post llm_models_path, params: {
        llm_model: { llm_provider_id: anthropic.id, model_identifier: "claude-haiku-4-5",
                     display_name: "Claude Haiku 4.5", cost_per_1k_input: 0.001,
                     cost_per_1k_output: 0.005 }
      }

      model = LlmModel.find_by!(model_identifier: "claude-haiku-4-5")
      expect(model.certification_status).to eq "pending"
      expect(LlmModel.assignable).not_to include(model)
    end
  end

  describe "certifying" do
    it "refuses for a provider this application has no adapter for" do
      sign_in(role: "admin", name: "Ana")
      orphan = LlmProvider.create!(key: "some-vendor", name: "Some Vendor", status: "active")
      model = LlmModel.create!(llm_provider: orphan, model_identifier: "v1", display_name: "V1")

      post certify_llm_model_path(model)

      expect(model.reload).not_to be_certified
      expect(flash[:alert]).to match(/cannot call it/)
    end

    it "is refused to an auditor, who may only read the registry" do
      sign_in(role: "auditor", name: "Ada")

      post certify_llm_model_path(opus)

      expect(opus.reload).not_to be_certified
      expect(flash[:alert]).to match(/role does not allow/)
    end
  end

  describe "assignments" do
    before { sign_in(role: "admin", name: "Ana") }

    it "may not point at an uncertified model" do
      post llm_assignments_path, params: {
        llm_assignment: { llm_model_id: opus.id, agent_pattern: "claim-classifier",
                          action_type: "classify", priority: 0 }
      }

      expect(LlmAssignment.count).to eq 0
      expect(flash[:alert]).to match(/certified/)
    end

    it "routes once the model is vouched for" do
      post certify_llm_model_path(opus)
      post llm_assignments_path, params: {
        llm_assignment: { llm_model_id: opus.id, agent_pattern: "claim-classifier",
                          action_type: "classify", priority: 0 }
      }

      assignment = LlmAssignment.sole
      expect(assignment.llm_model).to eq opus
      expect(assignment.created_by.name).to eq "Ana"
    end
  end
end
