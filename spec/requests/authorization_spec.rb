require "rails_helper"

# Roles compose into capabilities in User, and policies ask capability
# questions. This is the table that says what each role may actually do.
RSpec.describe "authorisation", type: :request do
  before { seed_quietly }

  let(:document) { Document.create!(body: "A claim.") }

  describe "signed out" do
    it "sends you to sign in rather than to the work" do
      get documents_path

      expect(response).to redirect_to(new_session_path)
    end

    it "remembers where you were headed" do
      get document_path(document)
      sign_in

      expect(response).to redirect_to(document_path(document))
    end
  end

  describe "viewer" do
    before { sign_in(role: "viewer", name: "Viv") }

    it "may read the work" do
      get documents_path
      expect(response).to have_http_status(:ok)
    end

    it "may not submit a text" do
      get new_document_path

      expect(flash[:alert]).to match(/role does not allow/)
    end

    it "may not run an analysis" do
      post classify_document_path(document)

      expect(flash[:alert]).to match(/role does not allow/)
      expect(ClassifyDocumentJob).to have_been_enqueued.exactly(0).times
    end

    it "may not see the model registry" do
      get llm_models_path

      expect(flash[:alert]).to match(/role does not allow/)
    end
  end

  describe "reviewer" do
    before { sign_in(role: "reviewer", name: "Rae") }

    it "may submit a text and run an analysis" do
      get new_document_path
      expect(response).to have_http_status(:ok)
    end

    # Certification decides what may influence every judgement, so it is
    # narrower than reviewing.
    it "may not see or certify models" do
      get llm_models_path

      expect(flash[:alert]).to match(/role does not allow/)
    end
  end

  describe "auditor" do
    before { sign_in(role: "auditor", name: "Ada") }

    it "may read the registry and the invocations" do
      get llm_models_path
      expect(response).to have_http_status(:ok)

      get llm_invocations_path
      expect(response).to have_http_status(:ok)
    end

    # Reading the record is not the same as changing what produced it.
    it "may not certify a model" do
      model = LlmModel.first

      post certify_llm_model_path(model)

      expect(flash[:alert]).to match(/role does not allow/)
      expect(model.reload).not_to be_certified
    end

    it "may not review" do
      post classify_document_path(document)

      expect(flash[:alert]).to match(/role does not allow/)
    end
  end

  describe "admin" do
    before { sign_in(role: "admin", name: "Avery") }

    it "may certify a model, and the certification carries their name" do
      model = LlmModel.first

      post certify_llm_model_path(model)

      expect(model.reload).to be_certified
      expect(model.certified_by.name).to eq "Avery"
    end

    # Revocation is terminal, so it is an admin act too.
    it "may revoke one" do
      model = LlmModel.first
      post certify_llm_model_path(model)

      post revoke_llm_model_path(model), params: { reason: "unattributable output" }

      expect(model.reload).to be_revoked
      expect(model.revocation_reason).to include "unattributable"
    end
  end

  # Authorisation answers "may you"; the graph answers "who did". Keeping them
  # separate is why credentials never appear in the audit trail.
  describe "the identity split" do
    it "attributes a judgement to the Referent, not the User" do
      user = sign_in(role: "reviewer", name: "Rae")
      post documents_path, params: { document: { body: "I saw Pugsley leave." } }
      flagged = Document.order(:created_at).last

      patch flag_path(flagged.flags.first), params: { disposition: "accepted" }

      disposition = flagged.flags.first.assertions.sole
      expect(disposition.asserter).to eq user.referent
      expect(disposition.asserter).to be_a(Referent)
      expect(Assertion.column_names).not_to include("user_id")
    end
  end
end
