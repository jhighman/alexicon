require "rails_helper"

# Structure cannot tell "Ketamine" from "Alec" — both are capitalised words the
# extractor has never seen. That distinction is world knowledge, so it is asked
# of a person once and remembered.
RSpec.describe "answering an identity STOP", type: :request do
  before { seed_quietly }
  before { sign_in }



  def ingest(body)
    post documents_path, params: { document: { body: body } }
    Document.order(:created_at).last
  end


  # A judgement about a name applies wherever that name appears. Answering the
  # same question once per occurrence is the same answer typed again, and on a
  # real essay it meant 204 questions for 144 distinct names.
  describe "answering once, for every occurrence" do
    it "resolves every mention of a name that is grounded" do
      document = ingest("Polanyi wrote it. Polanyi meant it. Polanyi was right.")
      expect(document.open_stops.count).to eq 3

      post ground_mention_path(document.mentions.first),
           params: { referent: { subject: "Person", role: "Philosopher" } }

      document.reload
      expect(document.mentions.map(&:status).uniq).to eq [ "resolved" ]
      expect(document.open_stops).to be_empty
      expect(document).to be_executable
    end

    it "clears every mention of a form marked not a subject" do
      document = ingest("Every day is like this. Every night too. Every time.")
      expect(document.open_stops.count).to be >= 2

      post ignore_mention_path(document.mentions.first)

      expect(document.reload.open_stops).to be_empty
      expect(IgnoredForm.ignores?("Every")).to be true
    end

    # The graph, not just the document on screen: the referent it creates is
    # global, so leaving other documents flagged would contradict it.
    it "reaches occurrences in other documents too" do
      first = ingest("Polanyi wrote it.")
      second = ingest("Polanyi was right.")

      post ground_mention_path(first.mentions.sole),
           params: { referent: { subject: "Person", role: "Philosopher" } }

      expect(second.reload.open_stops).to be_empty
    end
  end

  describe "grounding a name" do
    it "creates the referent, resolves the mention and lifts the lock" do
      document = ingest("Alec wrote about it.")
      mention = document.mentions.sole
      expect(document.executable?).to be false

      post ground_mention_path(mention), params: { referent: { subject: "Family", role: "Friend" } }

      expect(mention.reload.status).to eq "resolved"
      expect(mention.referent.passport).to eq "Alec → Family → Friend"
      expect(document.reload.executable?).to be true
    end

    it "supersedes the STOP rather than leaving two judgements standing" do
      document = ingest("Alec wrote about it.")
      mention = document.mentions.sole

      post ground_mention_path(mention), params: { referent: { subject: "Family", role: "Friend" } }

      expect(mention.reload.assertions.standing.count).to eq 1
      expect(mention.assertions.count).to eq 2
      expect(mention.flags).to be_empty
    end

    # A partial passport is not a weaker anchor; it is no anchor.
    it "refuses an incomplete passport" do
      document = ingest("Alec wrote about it.")
      mention = document.mentions.sole

      post ground_mention_path(mention), params: { referent: { subject: "Family", role: "" } }

      expect(mention.reload.status).to eq "unanchored"
      expect(document.reload.executable?).to be false
    end

    # Grounding writes a durable decision into the graph, so it needs the
    # capability, not merely a session.
    it "refuses a role that may not review" do
      document = ingest("Alec wrote about it.")
      mention = document.mentions.sole
      delete session_path
      sign_in(role: "viewer", name: "Viv")

      post ground_mention_path(mention), params: { referent: { subject: "Family", role: "Friend" } }

      expect(flash[:alert]).to match(/role does not allow/)
      expect(mention.reload.status).to eq "out_of_distribution"
    end
  end

  describe "marking a form as not a subject" do
    it "records the decision with its author and sets the flag aside" do
      document = ingest("Ketamine blocks receptors.")
      mention = document.mentions.sole

      post ignore_mention_path(mention)

      entry = IgnoredForm.find_by!(form: "Ketamine")
      expect(entry.decided_by.name).to eq "Jeff"
      # The flag still stands — it was answered, not superseded. Contrast with
      # grounding, where re-verification supersedes it outright.
      expect(mention.reload.flags.count).to eq 1
      expect(mention.flags.none?(&:open?)).to be true
      expect(document.reload.executable?).to be true
    end

    it "stops proposing that form in later documents" do
      first = ingest("Ketamine blocks receptors.")
      post ignore_mention_path(first.mentions.sole)

      second = ingest("Ketamine was administered.")

      expect(second.mentions).to be_empty
      expect(second.executable?).to be true
    end

    # The record of why this was ever blocked stays intact.
    it "sets the flag aside rather than deleting it" do
      document = ingest("Ketamine blocks receptors.")
      mention = document.mentions.sole

      post ignore_mention_path(mention)

      expect(mention.reload.assertions.acting("flag").count).to eq 1
      expect(mention.assertions.acting("flag").sole.disposition).to eq "rejected"
    end
  end

  describe "acronyms" do
    # Capitalisation explained by acronym convention is not evidence of a
    # proper noun on its own.
    it "does not propose an unknown all-capital token" do
      document = ingest("The NMDA receptor was blocked.")

      expect(document.mentions).to be_empty
      expect(document.executable?).to be true
    end

    it "still proposes one that is already known" do
      Referent.create!(name: "NASA", subject: "Organisation", role: "Agency", primitive: "entity")

      document = ingest("The NASA report was published.")

      expect(document.mentions.map(&:text)).to include "NASA"
    end
  end
end
