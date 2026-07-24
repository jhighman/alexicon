require "rails_helper"

RSpec.describe "the review surface", type: :request do
  before { seed_quietly }

  # Seeds print a summary line; keep the spec output readable.
  def seed_quietly
    original, $stdout = $stdout, StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original
  end

  def ingest(body, title: nil)
    post documents_path, params: { document: { body: body, title: title } }
    Document.order(:created_at).last
  end

  def identify(name)
    post reviewer_path, params: { referent: { name: name } }
  end

  describe "listing" do
    it "renders an empty state before anything is reviewed" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include "Nothing has been reviewed yet"
    end

    it "lists ingested documents with their state" do
      ingest("Pugsley left.", title: "A note")

      get documents_path

      expect(response.body).to include "A note"
      expect(response.body).to include "Locked"
    end
  end

  describe "ingesting" do
    it "turns pasted text into a reviewable document" do
      document = ingest("I saw a wall collapse. Therefore God exists.")

      expect(response).to redirect_to(document)
      expect(document.claims.count).to eq 2
      follow_redirect!
      expect(response.body).to include "I saw a wall collapse."
    end

    it "refuses empty input rather than creating a blank document" do
      post documents_path, params: { document: { body: "   " } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include "Paste some text"
      expect(Document.count).to eq 0
    end
  end

  describe "showing a document" do
    it "surfaces the flags waiting on a person" do
      document = ingest("Pugsley left the house.")

      get document_path(document)

      expect(response.body).to include "Waiting on you"
      expect(response.body).to include "Identity not established"
    end

    # The language of the interface has to carry the same discipline as the model.
    it "states that a flag is not a claim of falsehood" do
      document = ingest("Pugsley left.")

      get document_path(document)

      expect(response.body).to include "A flag never says a claim is false"
    end

    it "shows the audit trail with its authors" do
      document = ingest("Pugsley left.")

      get document_path(document)

      expect(response.body).to include "Identity Sentinel"
      expect(response.body).to include "Record"
    end
  end

  describe "answering a flag" do
    # Every judgement needs an accountable author -- including this one.
    it "will not accept a disposition from nobody" do
      document = ingest("Pugsley left.")
      flag = document.flags.first

      patch flag_path(flag), params: { disposition: "accepted" }

      expect(response).to redirect_to(new_reviewer_path)
      expect(flag.reload.disposition).to eq "open"
    end

    it "records the disposition against the named reviewer" do
      document = ingest("Pugsley left.")
      flag = document.flags.first
      identify("Jeff")

      patch flag_path(flag), params: { disposition: "accepted" }

      expect(flag.reload.disposition).to eq "accepted"
      expect(flag.assertions.sole.asserter.name).to eq "Jeff"
    end

    it "lifts the execution lock once the STOP is answered" do
      document = ingest("Pugsley left.")
      identify("Jeff")
      expect(document.executable?).to be false

      document.flags.select(&:stop?).each do |flag|
        patch flag_path(flag), params: { disposition: "accepted" }
      end

      expect(document.reload.executable?).to be true
    end

    it "leaves the flag itself untouched" do
      document = ingest("Pugsley left.")
      flag = document.flags.first
      identify("Jeff")

      patch flag_path(flag), params: { disposition: "rejected" }

      expect(flag.reload.message).to start_with "Identity not established"
      expect(flag).to be_readonly
    end

    it "rejects a disposition it does not recognise" do
      document = ingest("Pugsley left.")
      flag = document.flags.first
      identify("Jeff")

      patch flag_path(flag), params: { disposition: "ignored" }

      expect(flag.reload.disposition).to eq "open"
    end
  end

  describe "identifying" do
    it "requires a name" do
      post reviewer_path, params: { referent: { name: "  " } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include "A name is required"
    end

    it "reuses an existing person rather than duplicating them" do
      Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")

      expect { identify("Jeff") }.not_to change(Referent, :count)
    end

    it "returns the reviewer to the page they were on" do
      document = ingest("Pugsley left.")
      flag = document.flags.first
      patch flag_path(flag), params: { disposition: "accepted" },
            headers: { "HTTP_REFERER" => document_path(document) }

      identify("Jeff")

      expect(response).to redirect_to(document_path(document))
    end
  end
end
