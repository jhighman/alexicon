require "rails_helper"

# The screen a person types claims on. What it must never do is show them what
# the machine said, so most of this is about what is absent from the page.
RSpec.describe "typing claims blind", type: :request do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:machine) { Referent.find_by!(key: "claim-classifier") }
  let(:document) { Document.create!(body: "…") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(position, text = "Claim #{position}.")
    document.claims.create!(position: position, text: text)
  end

  # Per-request tokens differ between two identical renders; nothing else should.
  def scrub(body) = body.gsub(/value="[^"]{40,}"/, "")

  describe "the typing screen" do
    let!(:target) { claim(2, "The wall represented fear.") }

    # Every category name is on the page as an option, so no wording check can
    # prove nothing leaked. This can: the page must be byte-identical whether or
    # not the machine has an opinion about the claim.
    it "renders identically whether or not the machine has typed the claim" do
      sign_in
      get document_blind_reading_path(document) # consumes the sign-in flash
      get document_blind_reading_path(document)
      blind = scrub(response.body)

      3.times { target.classify!(category("ontological"), asserter: machine, confidence: 0.9) }
      get document_blind_reading_path(document)

      expect(scrub(response.body)).to eq blind
    end

    it "shows the claim, and no reading of it" do
      3.times { target.classify!(category("ontological"), asserter: machine, confidence: 0.9) }
      sign_in

      get document_blind_reading_path(document)

      expect(response.body).to include "The wall represented fear."
      expect(response.body).not_to match(/3 of 3|readings|the system said|already typed/i)
    end

    it "offers every category, so the answer is not narrowed either" do
      sign_in

      get document_blind_reading_path(document)

      framework.claim_categories.each { expect(response.body).to include it.name }
    end

    it "shows the preceding claims as plain text" do
      earlier = claim(1, "The wall fell.")
      sign_in
      post document_blind_reading_path(document),
           params: { claim_id: earlier.id, claim_category_id: category("objective").id }

      get document_blind_reading_path(document)

      expect(response.body).to include "The wall fell.", "The wall represented fear."
    end

    it "sends the reader to the comparison once nothing is left to type" do
      sign_in
      post document_blind_reading_path(document),
           params: { claim_id: target.id, claim_category_id: category("interpretive").id }

      get document_blind_reading_path(document)

      expect(response).to redirect_to comparison_document_blind_reading_path(document)
    end
  end

  describe "recording a reading" do
    let!(:target) { claim(1) }

    it "attributes it to the person, not to their account" do
      user = sign_in

      post document_blind_reading_path(document),
           params: { claim_id: target.id, claim_category_id: category("interpretive").id,
                     rationale: "it reads a meaning into the fact" }

      assertion = target.reload.classification
      expect(assertion.asserter).to eq user.referent
      expect(assertion.claim["rationale"]).to eq "it reads a meaning into the fact"
      expect(target.category.key).to eq "interpretive"
    end

    it "records that the reader could have argued it the other way" do
      sign_in

      post document_blind_reading_path(document),
           params: { claim_id: target.id, claim_category_id: category("objective").id, unsure: "1" }

      expect(target.reload.classification.claim["confidence"]).to eq BlindReading::UNSURE
    end

    it "records an abstention without blanking what the machine agreed on" do
      3.times { target.classify!(category("ontological"), asserter: machine, confidence: 0.9) }
      sign_in

      post document_blind_reading_path(document), params: { claim_id: target.id, abstain: "I cannot tell" }

      expect(target.reload.category.key).to eq "ontological"
      expect(target.classifications.count).to eq 4
    end

    it "asks again rather than recording nothing when no category was picked" do
      sign_in

      post document_blind_reading_path(document), params: { claim_id: target.id }

      expect(response).to redirect_to document_blind_reading_path(document)
      expect(flash[:alert]).to match(/Pick a category/)
      expect(target.reload.classifications).to be_empty
    end
  end

  describe "the comparison" do
    it "shows only what this reader has already answered" do
      answered = claim(1, "The wall fell.")
      unanswered = claim(2, "The wall represented fear.")
      answered.classify!(category("observation"), asserter: machine, confidence: 0.9)
      unanswered.classify!(category("ontological"), asserter: machine, confidence: 0.9)
      sign_in
      post document_blind_reading_path(document),
           params: { claim_id: answered.id, claim_category_id: category("objective").id }

      get comparison_document_blind_reading_path(document)

      expect(response.body).to include "The wall fell."
      expect(response.body).not_to include "The wall represented fear."
    end

    it "says there is nothing to compare before anything has been typed" do
      claim(1)
      sign_in

      get comparison_document_blind_reading_path(document)

      expect(response.body).to match(/have not typed anything yet/)
    end
  end

  describe "who may type" do
    before { claim(1) }

    it "refuses a viewer, since typing writes a judgement that outranks the machine's" do
      sign_in(role: "viewer", name: "Vera")

      get document_blind_reading_path(document)

      expect(response).to redirect_to root_path
      expect(flash[:alert]).to match(/role does not allow/)
    end

    it "refuses anyone who is not signed in" do
      get document_blind_reading_path(document)

      expect(response).to redirect_to new_session_path
    end
  end
end
