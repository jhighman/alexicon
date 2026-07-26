require "rails_helper"

# An agent typing claims. The act the programmatic surface was built for: a
# review decision the application expects a person to make, made by something
# that is not one, on the record, as itself.
RSpec.describe "the blind reading API", type: :request do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:agent) do
    Referent.create!(key: "second-reader", name: "Second Reader", subject: "System",
                     role: "Reviewer", primitive: "system")
  end

  let(:agent_token) { ApiToken.issue!(referent: agent, name: "spec", role: "reviewer") }
  let(:human_token) { ApiToken.issue!(referent: person, name: "spec", role: "reviewer") }

  def auth(token) = { "Authorization" => "Bearer #{token.plaintext}" }
  def json = JSON.parse(response.body)
  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  let(:document) { Document.create!(body: "…") }

  def claim(position, text = "Claim #{position}.")
    document.claims.create!(position: position, text: text)
  end

  def delegate!(act = "type_claim")
    Delegation.create!(agent_pattern: "second-reader", act: act, granted_by: person)
  end

  describe "asking what to type" do
    let!(:target) { claim(1, "The wall represented fear.") }

    before { 3.times { target.classify!(category("ontological"), asserter: classifier, confidence: 0.9) } }

    it "needs no delegation, because reading decides nothing" do
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(response).to have_http_status(:ok)
      expect(json["claim"]["text"]).to eq "The wall represented fear."
    end

    # The property the measurement rests on. Every category name is in the
    # payload as an option, so no field check could prove nothing leaked — but
    # this can: the response cannot vary with what the classifier concluded.
    it "returns the same payload however the classifier has typed the claim" do
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)
      blind = response.body

      3.times { target.classify!(category("objective"), asserter: classifier, confidence: 0.9) }
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(response.body).to eq blind
    end

    it "carries nothing on the claim but the claim" do
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["claim"].keys).to match_array %w[id position text]
    end

    it "gives the categories with their definitions, so the judge is asked the same question" do
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["categories"].map { it["key"] })
        .to match_array framework.claim_categories.map(&:key)
      expect(json["categories"].first["definition"]).to be_present
    end

    it "gives the preceding claims as text" do
      claim(2, "So it was always going to fall.")
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)
      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(agent_token)
      delegate!

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(agent_token)
      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["context"]).to eq [ "The wall represented fear." ]
    end

    it "reports progress and says when there is nothing left" do
      delegate!
      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(agent_token)

      get api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["complete"]).to be true
      expect(json["claim"]).to be_nil
      expect(json).to include("typed" => 1, "total" => 1)
    end
  end

  describe "typing one" do
    let!(:target) { claim(1) }

    it "refuses an agent with no delegation, and names the act" do
      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(agent_token)

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq "not_delegated"
      expect(json["act"]).to eq "type_claim"
      expect(target.reload.classifications).to be_empty
    end

    it "records the reading as the agent's own once a person has delegated it" do
      delegate!

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive", rationale: "reads meaning in" },
           headers: auth(agent_token)

      expect(response).to have_http_status(:created)
      expect(json).to include("decided_by" => "Second Reader", "blind" => true,
                              "category" => "interpretive")
      expect(target.reload.classifications.last.asserter).to eq agent
    end

    # The whole reason a second judge can be polled safely.
    it "does not let the agent's reading move what the classifier concluded" do
      3.times { target.classify!(category("ontological"), asserter: classifier, confidence: 0.9) }
      delegate!

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(agent_token)

      expect(json["counts_toward_classification"]).to be false
      expect(target.reload.category.key).to eq "ontological"
      expect(target.machine_agreement.to_s).to eq "3 of 3"
    end

    # And the reason a person's does.
    it "lets a person's reading settle it, no delegation needed" do
      3.times { target.classify!(category("ontological"), asserter: classifier, confidence: 0.9) }

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(human_token)

      expect(json["counts_toward_classification"]).to be true
      expect(target.reload.category.key).to eq "interpretive"
    end

    it "records an abstention as an answer" do
      delegate!

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, abstain: "true" }, headers: auth(agent_token)

      expect(json).to include("abstained" => true, "category" => nil)
      expect(target.reload.classifications.count).to eq 1
    end

    it "names the categories it would have accepted when given one it does not know" do
      delegate!

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "metaphysical" }, headers: auth(agent_token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["detail"]).to include "objective", "abstain=true"
    end

    it "refuses a viewer token even when the act has been delegated" do
      delegate!
      viewer = ApiToken.issue!(referent: agent, name: "reader", role: "viewer")

      post api_v1_document_blind_reading_path(document),
           params: { claim_id: target.id, category: "interpretive" }, headers: auth(viewer)

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq "forbidden"
    end
  end

  describe "the comparison" do
    it "rates agreement over what both typed, and shows where they part" do
      agreeing = claim(1, "The wall fell.")
      parting = claim(2, "The wall represented fear.")
      agreeing.classify!(category("observation"), asserter: classifier, confidence: 0.9)
      parting.classify!(category("ontological"), asserter: classifier, confidence: 0.9)
      delegate!
      post api_v1_document_blind_reading_path(document),
           params: { claim_id: agreeing.id, category: "observation" }, headers: auth(agent_token)
      post api_v1_document_blind_reading_path(document),
           params: { claim_id: parting.id, category: "interpretive", unsure: "true" },
           headers: auth(agent_token)

      get comparison_api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["agreement"]).to include("rate" => 0.5, "agreed" => 1, "compared" => 2)
      expect(json["sure_disagreements"]).to eq 0
      expect(json["moves"]).to eq({ "ontological->interpretive" => 1 })
      expect(json["disagreements"].first)
        .to include("yours" => "interpretive", "classifier" => "ontological", "unsure" => true)
    end

    it "says plainly that agreement between two judges is not correctness" do
      claim(1)

      get comparison_api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["note"]).to include "not correctness"
    end

    it "shows one agent nothing of another's readings" do
      target = claim(1)
      other = Referent.create!(key: "third-reader", name: "Third", subject: "System",
                               role: "Reviewer", primitive: "system")
      BlindReading.new(document, reader: other).record!(target, category: category("objective"))

      get comparison_api_v1_document_blind_reading_path(document), headers: auth(agent_token)

      expect(json["typed"]).to eq 0
    end
  end
end
