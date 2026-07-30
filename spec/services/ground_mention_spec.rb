require "rails_helper"

# Answering an identity STOP. The browser and the API drive this one
# implementation, and until now nothing drove it in a spec — which is how the
# resolutions it records came to be attributed to the Sentinel rather than to
# whoever answered.
RSpec.describe GroundMention do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0") }
  let(:identity_domain) do
    Domain.create!(framework: framework, key: "identity", name: "Identity",
                   position: 1, question: "Who or what exists?")
  end
  let!(:identity_sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system", domain: identity_domain)
  end
  let(:reviewer) do
    Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
  end
  let(:document) { Document.create!(body: "…") }

  def mention(text, position: 1)
    document.claims.create!(position: position, text: "#{text} left.").mentions.create!(text: text)
  end

  describe "grounding a new subject" do
    it "creates the referent from the passport it was given" do
      result = described_class.call(mention("Wednesday"), by: reviewer,
                                    subject: "Family", role: "Sister")

      expect(result.referent.name).to eq "Wednesday"
      expect(result.referent.subject).to eq "Family"
      expect(result.referent.primitive).to eq "entity"
    end

    it "refuses a partial passport — half an anchor is no anchor" do
      expect { described_class.call(mention("Wednesday"), by: reviewer, subject: "Family") }
        .to raise_error(described_class::IncompletePassport)
    end

    it "makes a Person a person, so their judgements read as decisions" do
      result = described_class.call(mention("Ana"), by: reviewer, subject: "Person", role: "Author")

      expect(result.referent.primitive).to eq "person"
    end
  end

  # THE fix. A decision recorded as the Sentinel's inference is the
  # misattribution this system exists to catch, committed at the layer
  # everything else stands on.
  describe "who the resolution names" do
    it "attributes it to whoever answered, not to the Sentinel that checked" do
      m = mention("Wednesday")

      described_class.call(m, by: reviewer, subject: "Family", role: "Sister")

      expect(m.reload.resolution.asserter).to eq reviewer
      expect(m.resolution).not_to be_inferred
    end

    it "marks it grounded, so it is not read as an automatic match" do
      m = mention("Wednesday")

      described_class.call(m, by: reviewer, subject: "Family", role: "Sister")

      expect(m.reload.resolution.claim["grounded"]).to be true
    end

    it "attributes an agent's grounding to the agent, still marked as a decision" do
      agent = Referent.create!(name: "Identity Grounder", subject: "System", role: "Reviewer",
                               primitive: "system")
      m = mention("Wednesday")

      described_class.call(m, by: agent, subject: "Family", role: "Sister")

      expect(m.reload.resolution.asserter).to eq agent
      expect(m.resolution).to be_inferred
      expect(m.resolution.claim["grounded"]).to be true
    end

    # One decision, however many times the name appears.
    it "carries the same attribution to every occurrence of the name" do
      first = mention("Wednesday", position: 1)
      second = mention("Wednesday", position: 2)

      result = described_class.call(first, by: reviewer, subject: "Family", role: "Sister")

      expect(result.occurrences).to eq 2
      expect(second.reload.resolution.asserter).to eq reviewer
    end
  end

  describe "grounding a name as another spelling" do
    it "records the alias rather than correcting the document" do
      existing = Referent.create!(name: "Polanyi", subject: "Person", role: "Philosopher",
                                  primitive: "person")
      m = mention("Polayani")

      result = described_class.call(m, by: reviewer, same_as: existing)

      expect(result.referent).to eq existing
      expect(ReferentAlias.find_by(name: "Polayani").referent).to eq existing
      expect(m.reload.text).to eq "Polayani"
    end

    it "attributes the judgement that two names are one subject to whoever made it" do
      existing = Referent.create!(name: "Polanyi", subject: "Person", role: "Philosopher",
                                  primitive: "person")
      m = mention("Polayani")

      described_class.call(m, by: reviewer, same_as: existing)

      expect(m.reload.resolution.asserter).to eq reviewer
      expect(ReferentAlias.find_by(name: "Polayani").source).to include "Jeff"
    end
  end
end
