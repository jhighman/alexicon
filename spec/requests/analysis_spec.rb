require "rails_helper"

RSpec.describe "running an analysis", type: :request do
  before { seed_quietly }

  def seed_quietly
    original, $stdout = $stdout, StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original
  end

  def ingest(body)
    post documents_path, params: { document: { body: body } }
    Document.order(:created_at).last
  end

  def unlock(document)
    post reviewer_path, params: { referent: { name: "Jeff" } }
    document.open_stops.each { patch flag_path(it), params: { disposition: "accepted" } }
    document.reload
  end

  # Every proper noun here is already grounded, so ingest raises no STOPs and
  # the document is executable without anyone answering a flag.
  def clean_document
    Referent.create!(name: "Morticia", subject: "Family", role: "Mother", primitive: "person")
    ingest("Morticia saw a wall collapse. It represented fear.")
  end

  describe "classifying" do
    it "refuses while identity is unresolved, and says why" do
      document = ingest("Pugsley left.")

      post classify_document_path(document)

      expect(flash[:alert]).to match(/Identity has to be established first/)
      expect(ClassifyDocumentJob).to have_been_enqueued.exactly(0).times
    end

    it "refuses without an API key rather than failing in the background" do
      document = ingest("Pugsley left.")
      unlock(document)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)

      post classify_document_path(document)

      expect(flash[:alert]).to match(/ANTHROPIC_API_KEY/)
    end

    it "enqueues the job once the document is executable" do
      document = ingest("Pugsley left.")
      unlock(document)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("sk-test")

      expect { post classify_document_path(document) }
        .to have_enqueued_job(ClassifyDocumentJob).with(document)
      expect(response).to redirect_to(document)
    end
  end

  describe "judging" do
    it "refuses while identity is unresolved" do
      document = ingest("Pugsley left.")

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

      expect(response.body).to include "Last classified by Claim Classifier"
      expect(response.body).to include "the classifier declined rather than guess"
    end
  end
end
