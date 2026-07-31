require "rails_helper"

RSpec.describe "running an analysis", type: :request do
  before { seed_quietly }
  before { sign_in }



  def ingest(body)
    post documents_path, params: { document: { body: body } }
    Document.order(:created_at).last
  end

  # Certify the seeded Anthropic model and route the classifier to it, so the
  # readiness check has a governed answer to find.
  def arm_classifier(key: "sk-test")
    provider = LlmProvider.find_by!(key: "anthropic")
    provider.update!(status: "active")
    provider.set_api_key!(key, by: Referent.where(primitive: "person").first)
    model = LlmModel.find_by!(model_identifier: "claude-opus-5")
    model.certify!(Referent.where(primitive: "person").first)
    LlmAssignment.create!(llm_model: model, agent_pattern: "claim-classifier",
                          action_type: "classify")
    model
  end

  def unlock(document)
    document.open_stops.each { patch flag_path(it), params: { disposition: "accepted" } }
    document.reload
  end

  # Every proper noun here is already grounded, so ingest raises no STOPs and
  # the document is executable without anyone answering a flag.
  def clean_document
    Referent.create!(name: "Morticia", subject: "Family", role: "Mother", primitive: "person")
    ingest("I watched Morticia see a wall collapse. It represented fear.")
  end

  describe "classifying" do
    # A document full of names nobody has grounded is still readable. The old
    # behaviour refused, which made an essay citing unfamiliar authors
    # impossible to classify at all.
    it "proceeds while identity is unresolved" do
      arm_classifier
      document = ingest("I saw Pugsley leave.")

      expect(document.open_stops).to be_present
      expect { post classify_document_path(document) }
        .to have_enqueued_job(ClassifyDocumentJob).with(document)
    end

    it "refuses when no model is certified, rather than failing in the background" do
      document = ingest("I saw Pugsley leave.")
      unlock(document)

      post classify_document_path(document)

      expect(flash[:alert]).to match(/no model is certified/)
      expect(ClassifyDocumentJob).to have_been_enqueued.exactly(0).times
    end

    # The old guard checked ANTHROPIC_API_KEY directly, so it both missed a
    # stored key and named the wrong vendor once routing could point elsewhere.
    it "names the provider that would actually answer when its key is missing" do
      arm_classifier
      LlmProvider.find_by!(key: "anthropic").clear_api_key!
      document = ingest("I saw Pugsley leave.")
      unlock(document)

      with_env(ANTHROPIC_API_KEY: nil) { post classify_document_path(document) }

      expect(flash[:alert]).to match(/Claude Opus 5 would answer, but Anthropic has no API key/)
      expect(ClassifyDocumentJob).to have_been_enqueued.exactly(0).times
    end

    it "enqueues the job once a governed model is armed and the document is executable" do
      arm_classifier
      document = ingest("I saw Pugsley leave.")
      unlock(document)

      expect { post classify_document_path(document) }
        .to have_enqueued_job(ClassifyDocumentJob).with(document)
      expect(response).to redirect_to(document)
    end
  end

  describe "judging" do
    it "refuses while identity is unresolved" do
      document = ingest("I saw Pugsley leave.")

      post govern_document_path(document)

      expect(flash[:alert]).to match(/Identity has to be established first/)
    end

    it "enqueues the governance job" do
      document = clean_document

      expect { post govern_document_path(document) }
        .to have_enqueued_job(GovernDocumentJob).with(document)
    end
  end

  describe "the controls" do
    it "offers classification and reports that nothing is judged yet" do
      document = clean_document

      get document_path(document)

      expect(response.body).to include "Classify claims"
      expect(response.body).to include "Nothing has been classified yet"
    end

    it "disables judging until something has been classified" do
      document = clean_document

      get document_path(document)

      expect(response.body).to match(/Judge the steps.*disabled|disabled.*Judge the steps/m)
    end

    it "reports the run once one has happened" do
      document = clean_document
      category = ClaimCategory.find_by!(key: "observation")
      classifier = Referent.find_by!(key: "claim-classifier")
      document.claims.first.classify!(category, asserter: classifier)
      Assertion.create!(asserter: classifier, subject: document, act: "assert",
                        claim: { "run" => "classification", "classified" => 1,
                                 "abstained" => 1, "skipped" => 0 })

      get document_path(document)

      expect(response.body).to include "Last run by Claim Classifier"
      expect(response.body).to include "the classifier declined rather than guess"
    end

    # A pass that classified nothing because everything already had a category
    # is not the same as a pass that classified nothing because it failed.
    it "distinguishes a no-op re-run from a run that classified nothing" do
      document = clean_document
      category = ClaimCategory.find_by!(key: "observation")
      classifier = Referent.find_by!(key: "claim-classifier")
      document.claims.each { it.classify!(category, asserter: classifier) }
      Assertion.create!(asserter: classifier, subject: document, act: "assert",
                        claim: { "run" => "classification", "classified" => 0,
                                 "abstained" => 0, "skipped" => document.claims.count })

      get document_path(document)

      expect(response.body).to include "left alone as already classified"
    end
  end
end
