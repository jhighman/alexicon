require "rails_helper"

# The programmatic surface. Two gates, and both must pass: the same Pundit
# policy the browser uses, and — for judgements — a standing delegation saying
# this class of decision may be made with nobody present.
RSpec.describe "the acts API", type: :request do
  before { seed_quietly }

  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:agent) do
    Referent.create!(key: "review-agent", name: "Review Agent", subject: "System",
                     role: "Reviewer", primitive: "system")
  end

  def token_for(referent, role: "reviewer")
    ApiToken.issue!(referent: referent, name: "spec", role: role)
  end

  def auth(token) = { "Authorization" => "Bearer #{token.plaintext}" }

  def json = JSON.parse(response.body)

  let(:agent_token) { token_for(agent) }
  let(:human_token) { token_for(person) }

  # A document with one unresolved name in it.
  let(:document) do
    DocumentIngest.ingest!(body: "Polanyi wrote it. Polanyi meant it.").document
  end

  describe "authentication" do
    it "refuses a request with no token" do
      get api_v1_documents_path

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq "unauthenticated"
    end

    it "refuses a revoked token" do
      agent_token.revoke!(reason: "done")

      get api_v1_documents_path, headers: auth(agent_token)

      expect(response).to have_http_status(:unauthorized)
    end

    it "reads with a live token" do
      document

      get api_v1_documents_path, headers: auth(agent_token)

      expect(response).to have_http_status(:ok)
      expect(json["documents"].first["claims"]).to eq 2
    end
  end

  describe "reading is not judging" do
    it "lets an undelegated agent see the questions it may not answer" do
      get api_v1_document_mentions_path(document), headers: auth(agent_token)

      expect(response).to have_http_status(:ok)
      expect(json["names"].first["name"]).to eq "Polanyi"
      expect(json["names"].first["occurrences"]).to eq 2
    end
  end

  describe "grounding a name" do
    let(:mention) { document.mentions.first }

    # The posture the system starts in.
    it "refuses an agent with no delegation, and says which act was missing" do
      post ground_api_v1_mention_path(mention),
           params: { subject: "Person", role: "Philosopher" }, headers: auth(agent_token)

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq "not_delegated"
      expect(json["act"]).to eq "ground_mention"
      expect(document.reload.open_stops).to be_present
    end

    it "permits an agent once a person has delegated the act" do
      Delegation.create!(agent_pattern: "review-agent", act: "ground_mention", granted_by: person)

      post ground_api_v1_mention_path(mention),
           params: { subject: "Person", role: "Philosopher" }, headers: auth(agent_token)

      expect(response).to have_http_status(:ok)
      expect(json["occurrences"]).to eq 2
      expect(document.reload.open_stops).to be_empty
    end

    # The rule the whole surface turns on.
    it "attributes the judgement to the agent, and marks it inference" do
      Delegation.create!(agent_pattern: "*", act: "ground_mention", granted_by: person)

      post ground_api_v1_mention_path(mention),
           params: { subject: "Person", role: "Philosopher" }, headers: auth(agent_token)

      expect(json["decided_by"]).to eq "Review Agent"
      expect(json["inferred"]).to be true
      expect(document.reload.mentions.first.resolutions.last).to be_inferred
    end

    it "needs no delegation from a person's token" do
      post ground_api_v1_mention_path(mention),
           params: { subject: "Person", role: "Philosopher" }, headers: auth(human_token)

      expect(response).to have_http_status(:ok)
      expect(json["inferred"]).to be false
      expect(Delegation.count).to eq 0
    end

    it "refuses a partial passport" do
      post ground_api_v1_mention_path(mention),
           params: { subject: "Person" }, headers: auth(human_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["detail"]).to match(/subject and role/)
    end

    # Delegation widens whose judgement counts, never what the credential is for.
    it "still refuses a viewer token that has been delegated the act" do
      viewer = token_for(agent, role: "viewer")
      Delegation.create!(agent_pattern: "*", act: "ground_mention", granted_by: person)

      post ground_api_v1_mention_path(mention),
           params: { subject: "Person", role: "Philosopher" }, headers: auth(viewer)

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq "forbidden"
    end
  end

  describe "disposing a flag" do
    let(:flag) { document.open_stops.first }

    it "refuses an undelegated agent" do
      patch api_v1_flag_path(flag), params: { disposition: "accepted" }, headers: auth(agent_token)

      expect(response).to have_http_status(:forbidden)
      expect(flag.reload).to be_open
    end

    it "records the agent's disposition alongside the flag, never over it" do
      Delegation.create!(agent_pattern: "*", act: "dispose_flag", granted_by: person)

      patch api_v1_flag_path(flag), params: { disposition: "accepted" }, headers: auth(agent_token)

      expect(json["disposition"]).to eq "accepted"
      expect(json["inferred"]).to be true
      expect(flag.reload.act).to eq "flag"
    end

    it "rejects a disposition it does not recognise" do
      Delegation.create!(agent_pattern: "*", act: "dispose_flag", granted_by: person)

      patch api_v1_flag_path(flag), params: { disposition: "maybe" }, headers: auth(agent_token)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "running analyses" do
    it "refuses to queue governance while identity is unresolved" do
      post govern_api_v1_document_path(document), headers: auth(human_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["detail"]).to match(/identity is unresolved/)
      expect(GovernDocumentJob).to have_been_enqueued.exactly(0).times
    end

    it "refuses to queue classification when no model is routed" do
      post classify_api_v1_document_path(document), headers: auth(human_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["detail"]).to match(/no model is certified/)
    end

    it "queues identity proposals, and says they are only proposals" do
      expect {
        post propose_identities_api_v1_document_path(document), headers: auth(human_token)
      }.to have_enqueued_job(ProposeIdentitiesJob)

      expect(response).to have_http_status(:accepted)
      expect(json["note"]).to match(/lifts when someone accepts/)
    end
  end

  describe "ingesting" do
    it "accepts a text and reports what it found" do
      post api_v1_documents_path,
           params: { document: { body: "The wall fell. I saw it happen.", title: "note" } },
           headers: auth(human_token)

      expect(response).to have_http_status(:created)
      expect(json["ingested"]["claims"]).to eq 2
      expect(json["title"]).to eq "note"
    end

    it "refuses a viewer token" do
      post api_v1_documents_path, params: { document: { body: "The wall fell." } },
                                  headers: auth(token_for(person, role: "viewer"))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "certifying a model" do
    let(:model) { LlmModel.find_by!(model_identifier: "claude-opus-5") }

    it "is refused to an agent by default, certification being the narrowest capability" do
      admin_agent = token_for(agent, role: "admin")

      post certify_api_v1_llm_model_path(model), headers: auth(admin_agent)

      expect(response).to have_http_status(:forbidden)
      expect(model.reload).not_to be_certified
    end

    it "is permitted to a person's admin token" do
      admin = token_for(person, role: "admin")
      LlmProvider.find_by!(key: "anthropic").update!(status: "active")

      post certify_api_v1_llm_model_path(model), headers: auth(admin)

      expect(response).to have_http_status(:ok)
      expect(model.reload).to be_certified
      expect(model.certified_by).to eq person
    end
  end
end
