require "rails_helper"

# An agent may drive this system, and the record must never say a person did.
# That is the whole of what these two models are for.
RSpec.describe "agent identity" do
  let(:person) do
    Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let(:agent) do
    Referent.create!(key: "review-agent", name: "Review Agent", subject: "System",
                     role: "Reviewer", primitive: "system")
  end

  describe ApiToken do
    it "returns the secret once and never stores it" do
      token = described_class.issue!(referent: agent, name: "harness", role: "reviewer")

      expect(token.plaintext).to start_with "alx_"
      expect(described_class.find(token.id).plaintext).to be_nil
      expect(described_class.connection.select_value(
        "SELECT token_digest FROM api_tokens WHERE id = #{token.id}"
      )).not_to include token.plaintext
    end

    it "keeps only enough of it to tell two tokens apart" do
      token = described_class.issue!(referent: agent, name: "harness")

      expect(token.hint).to eq "…#{token.plaintext.last(4)}"
    end

    it "authenticates a live token and records that it was used" do
      token = described_class.issue!(referent: agent, name: "harness")

      found = described_class.authenticate(token.plaintext)

      expect(found).to eq token
      expect(found.last_used_at).to be_present
    end

    it "refuses a revoked token" do
      token = described_class.issue!(referent: agent, name: "harness")
      token.revoke!(reason: "harness finished")

      expect(described_class.authenticate(token.plaintext)).to be_nil
    end

    it "refuses an expired one" do
      token = described_class.issue!(referent: agent, name: "harness", expires_at: 1.hour.ago)

      expect(described_class.authenticate(token.plaintext)).to be_nil
    end

    it "refuses a wrong secret" do
      described_class.issue!(referent: agent, name: "harness")

      expect(described_class.authenticate("alx_not-the-secret")).to be_nil
      expect(described_class.authenticate(nil)).to be_nil
    end

    # The rule with no exceptions.
    it "is not human however wide its role" do
      token = described_class.issue!(referent: agent, name: "harness", role: "admin")

      expect(token.can_review?).to be true
      expect(token.can_certify_models?).to be true
      expect(token).not_to be_human
    end

    it "is human when the referent behind it is a person" do
      token = described_class.issue!(referent: person, name: "Ana's laptop", role: "reviewer")

      expect(token).to be_human
    end
  end

  describe Delegation do
    let(:token) { ApiToken.issue!(referent: agent, name: "harness", role: "reviewer") }

    # Absence of a row is refusal.
    it "permits nothing by default" do
      expect(token.may_judge?("dispose_flag")).to be false
      expect(Delegation.permits?(referent: agent, act: "dispose_flag")).to be false
    end

    it "permits an act a person has delegated, and only that act" do
      Delegation.create!(agent_pattern: "review-agent", act: "dispose_flag",
                         granted_by: person, rationale: "measuring verdict variance")

      expect(token.may_judge?("dispose_flag")).to be true
      expect(token.may_judge?("certify_model")).to be false
    end

    it "matches a family of agents by glob" do
      Delegation.create!(agent_pattern: "*-agent", act: "ground_mention",
                         granted_by: person, rationale: "a family of harness agents")

      expect(Delegation.permits?(referent: agent, act: "ground_mention")).to be true
    end

    it "records who granted it, so a delegation is itself attributable" do
      delegation = Delegation.create!(agent_pattern: "*", act: "dispose_flag",
                                      granted_by: person, rationale: "measuring verdict variance",
                                      expires_at: 3.days.from_now)

      expect(delegation.granted_by).to eq person
      expect(delegation.rationale).to be_present
    end

    it "stops permitting once deactivated, without losing the record of it" do
      delegation = Delegation.create!(agent_pattern: "review-agent", act: "dispose_flag",
                                      granted_by: person, rationale: "measuring variance")
      delegation.update!(active: false)

      expect(token.may_judge?("dispose_flag")).to be false
      expect(Delegation.find(delegation.id)).to be_present
    end

    it "stops permitting once expired" do
      Delegation.create!(agent_pattern: "review-agent", act: "dispose_flag",
                         granted_by: person, rationale: "measuring variance",
                         expires_at: 1.minute.ago)

      expect(token.may_judge?("dispose_flag")).to be false
    end

    # A person does not need permission to be the person the gate asked for.
    it "is not required of a person's token" do
      human_token = ApiToken.issue!(referent: person, name: "Ana's laptop", role: "reviewer")

      expect(Delegation.count).to eq 0
      expect(human_token.may_judge?("dispose_flag")).to be true
    end

    # Delegation widens whose judgement counts; it does not widen what the
    # credential is for.
    it "cannot lift an act the role never allowed" do
      viewer = ApiToken.issue!(referent: agent, name: "reader", role: "viewer")
      Delegation.create!(agent_pattern: "review-agent", act: "dispose_flag",
                         granted_by: person, rationale: "measuring variance")

      expect(viewer.may_judge?("dispose_flag")).to be false
    end
  end

  # One implementation of the capability questions, asked of either kind of actor.
  describe Capabilities do
    it "answers the same questions for a person and a token" do
      user = User.register!(username: "ana", password: "correct horse", role: "reviewer")
      token = ApiToken.issue!(referent: agent, name: "harness", role: "reviewer")

      %i[can_view? can_review? can_ingest? can_view_llm_registry? can_certify_models?].each do |q|
        expect(token.public_send(q)).to eq(user.public_send(q)), "#{q} disagreed"
      end
    end
  end

  # Alexandra Krížová's TEI inversion: authority tightens the justification
  # required of it rather than loosening it. Most systems run the other way,
  # which is the path by which a covert policy gets installed one reasonable
  # command at a time.
  describe "TEI inversion" do
    def delegation(pattern, act, **attrs)
      Delegation.new({ agent_pattern: pattern, act: act, granted_by: person }.merge(attrs))
    end

    it "asks nothing extra of a narrow delegation of a light act" do
      expect(delegation("review-agent", "ground_mention")).to be_valid
    end

    it "scores reach and consequence together" do
      expect(delegation("review-agent", "ground_mention").scrutiny).to eq 1
      expect(delegation("*", "certify_model").scrutiny).to eq 5
    end

    it "requires a reason once the delegation is heavy enough" do
      broad = delegation("*", "dispose_flag")

      expect(broad).not_to be_valid
      expect(broad.errors[:rationale].join).to match(/record why it was granted/)
    end

    it "requires an expiry when it is heavier still" do
      broad = delegation("*", "certify_model", rationale: "because")

      expect(broad).not_to be_valid
      expect(broad.errors[:expires_at].join).to match(/renewed deliberately/)
    end

    it "will not let a heavy permission outlive its reason" do
      far = delegation("*", "certify_model", rationale: "because", expires_at: 90.days.from_now)

      expect(far).not_to be_valid
      expect(far.errors[:expires_at].join).to match(/cannot be more than/)
    end

    it "permits the heaviest delegation when it carries what it must" do
      expect(delegation("*", "certify_model", rationale: "audited migration",
                             expires_at: 7.days.from_now)).to be_valid
    end

    # The anti-poisoning core: a system cannot widen its own authority and
    # record that a decision was made.
    it "refuses a delegation granted by an agent rather than a person" do
      by_agent = delegation("other-agent", "ground_mention", granted_by: agent)

      expect(by_agent).not_to be_valid
      expect(by_agent.errors[:granted_by].join).to match(/an agent cannot delegate judgement/)
    end

    it "weights certification above grounding, since it decides which model may judge at all" do
      expect(Delegation::ACT_WEIGHT["certify_model"]).to be > Delegation::ACT_WEIGHT["ground_mention"]
      expect(Delegation::ACT_WEIGHT["dispose_flag"]).to be > Delegation::ACT_WEIGHT["ignore_mention"]
    end

    it "treats a bare star as wider than a family, and a family as wider than one agent" do
      expect(delegation("*", "ground_mention").breadth).to eq 2
      expect(delegation("*-agent", "ground_mention").breadth).to eq 1
      expect(delegation("review-agent", "ground_mention").breadth).to eq 0
    end
  end
end
