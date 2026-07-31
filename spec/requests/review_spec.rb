require "rails_helper"

RSpec.describe "the review surface", type: :request do
  before { seed_quietly }
  before { sign_in }



  def ingest(body, title: nil)
    post documents_path, params: { document: { body: body, title: title } }
    Document.order(:created_at).last
  end


  describe "listing" do
    it "renders an empty state before anything is reviewed" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include "Nothing has been reviewed yet"
    end

    it "lists ingested documents with their state" do
      ingest("I saw Pugsley leave.", title: "A note")

      get documents_path

      expect(response.body).to include "A note"
      expect(response.body).to include "Identity unresolved"
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
    # One question per name, not per occurrence. The same essay previously
    # raised 204 separate STOPs for 144 distinct names.
    it "asks about each unresolved name once, however often it appears" do
      document = ingest("Pugsley left the house. I saw Pugsley return. Pugsley left again.")

      get document_path(document)

      expect(response.body).to include "Names with no established reference"
      expect(response.body).to include "Pugsley"
      expect(response.body).to include "3 occurrences"
      expect(document.open_stops.count).to eq 3
    end

    # The language of the interface has to carry the same discipline as the model.
    it "states that a flag is not a claim of falsehood" do
      document = ingest("I saw Pugsley leave.")

      get document_path(document)

      expect(response.body).to include "A flag never says a claim is false"
    end

    it "shows the audit trail with its authors" do
      document = ingest("I saw Pugsley leave.")

      get document_path(document)

      expect(response.body).to include "Identity Sentinel"
      expect(response.body).to include "Record"
    end
  end

  describe "answering a flag" do
    # Every judgement needs an accountable author, and now also an entitled one.
    it "will not accept a disposition from a role that may not review" do
      document = ingest("I saw Pugsley leave.")
      flag = document.flags.first
      delete session_path
      sign_in(role: "viewer", name: "Viv")

      patch flag_path(flag), params: { disposition: "accepted" }

      expect(flash[:alert]).to match(/role does not allow/)
      expect(flag.reload.disposition).to eq "open"
    end

    it "records the disposition against the named reviewer" do
      document = ingest("I saw Pugsley leave.")
      flag = document.flags.first

      patch flag_path(flag), params: { disposition: "accepted" }

      expect(flag.reload.disposition).to eq "accepted"
      expect(flag.assertions.sole.asserter.name).to eq "Jeff"
    end

    it "lifts the execution lock once the STOP is answered" do
      document = ingest("I saw Pugsley leave.")
      expect(document.executable?).to be false

      document.flags.select(&:stop?).each do |flag|
        patch flag_path(flag), params: { disposition: "accepted" }
      end

      expect(document.reload.executable?).to be true
    end

    it "leaves the flag itself untouched" do
      document = ingest("I saw Pugsley leave.")
      flag = document.flags.first

      patch flag_path(flag), params: { disposition: "rejected" }

      expect(flag.reload.message).to start_with "Identity not established"
      expect(flag).to be_readonly
    end

    it "rejects a disposition it does not recognise" do
      document = ingest("I saw Pugsley leave.")
      flag = document.flags.first

      patch flag_path(flag), params: { disposition: "ignored" }

      expect(flag.reload.disposition).to eq "open"
    end
  end

  describe "signing in" do
    it "rejects a bad password" do
      delete session_path

      post session_path, params: { username: "jeff", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include "do not match"
    end

    it "returns the reviewer to the page they were on" do
      document = ingest("I saw Pugsley leave.")
      delete session_path

      get document_path(document)
      expect(response).to redirect_to(new_session_path)

      sign_in(name: "Ada")
      expect(response).to redirect_to(document_path(document))
    end
  end
end
