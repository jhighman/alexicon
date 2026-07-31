require "rails_helper"

RSpec.describe "the domain sentinels" do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let(:document)  { Document.create!(body: "…") }

  def domain(key, question, position)
    Domain.create!(framework: framework, key: key, name: key.capitalize,
                   position: position, question: question)
  end

  def sentinel_for(key, question, position)
    Referent.create!(key: "#{key}-sentinel", name: "#{key.capitalize} Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system", domain: domain(key, question, position))
  end

  def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

  # A claim about a grounded person.
  def claim_about(text, person_name)
    c = claim(text)
    referent = Referent.find_by(name: person_name) ||
               Referent.create!(name: person_name, subject: "Family", role: "Friend", primitive: "person")
    m = c.mentions.create!(text: person_name)
    Assertion.create!(asserter: sentinel, subject: m, object: referent, act: "resolve",
                      claim: { "confidence" => 1.0 })
    c
  end

  let!(:sentinel) do
    Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end

  describe Sentinels::Agency do
    let!(:agency) { sentinel_for("agency", "What choices remain?", 2) }

    it "flags necessity asserted about a grounded person" do
      claim_about("Alec had no choice but to leave.", "Alec")

      flags = described_class.review!(document)

      expect(flags.sole.message).to include "no choice"
      expect(flags.sole.message).to include "What choices remain?"
      expect(flags.sole.asserter).to eq agency
    end

    # Necessity about the weather is not a collapse of anyone's agency.
    it "ignores necessity where no person is the subject" do
      claim("The collapse was inevitable.")

      expect(described_class.review!(document)).to be_empty
    end

    it "ignores a claim about a person with no necessity language" do
      claim_about("Alec wrote about it.", "Alec")

      expect(described_class.review!(document)).to be_empty
    end

    it "does not flag the same claim twice" do
      claim_about("Alec had no choice.", "Alec")
      described_class.review!(document)

      expect(described_class.review!(document)).to be_empty
    end
  end

  describe Sentinels::Motivation do
    let!(:motivation) { sentinel_for("motivation", "Why does this matter?", 3) }

    it "flags a prescription with no stated purpose" do
      claim("Everyone should try it.")

      flags = described_class.review!(document)

      expect(flags.sole.message).to include "nothing in the document says what it is for"
    end

    # The purpose may be stated in a neighbouring claim.
    it "stays quiet when the document says what the action is for" do
      claim("Everyone should try it.")
      claim("It helps because the pain subsides.")

      expect(described_class.review!(document)).to be_empty
    end

    it "ignores a claim that prescribes nothing" do
      claim("I saw a wall collapse.")

      expect(described_class.review!(document)).to be_empty
    end
  end

  describe Sentinels::Reflection do
    let!(:reflection) { sentinel_for("reflection", "Can this experience be viewed differently?", 4) }

    def category(key, rank)
      ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                            position: rank, justification_rank: rank,
                            definition: "…", confidence_source: "…")
    end

    it "flags a document whose claims have left their evidential base" do
      ontological = category("ontological", 3)
      claim("Therefore God exists.").classify!(ontological, asserter: sentinel)

      flags = described_class.review!(document)

      expect(flags.sole.message).to include "nothing in the document against which"
      expect(flags.sole.subject).to eq document
    end

    it "stays quiet when something grounds the interpretation" do
      observation = category("observation", 1)
      ontological = category("ontological", 3)
      claim("I saw a wall collapse.").classify!(observation, asserter: sentinel)
      claim("Therefore God exists.").classify!(ontological, asserter: sentinel)

      expect(described_class.review!(document)).to be_empty
    end

    # It cannot judge what has not been classified, and does not pretend to.
    it "stays quiet on an unclassified document" do
      claim("Therefore God exists.")

      expect(described_class.review!(document)).to be_empty
    end
  end

  describe Sentinels::Integration do
    let!(:integration) { sentinel_for("integration", "What larger pattern emerges?", 5) }

    it "flags a claim whose subject appears nowhere else" do
      claim_about("Alec wrote about it.", "Alec")
      claim_about("Alec left.", "Alec")
      claim_about("Morticia arrived.", "Morticia")

      flags = described_class.review!(document)

      expect(flags.sole.message).to include "Nothing else in this document is about Morticia"
    end

    it "stays quiet when every subject recurs" do
      claim_about("Alec wrote about it.", "Alec")
      claim_about("Alec left.", "Alec")
      claim_about("Alec returned.", "Alec")

      expect(described_class.review!(document)).to be_empty
    end

    # A claim with no grounded subject is ungrounded, which is Identity's
    # business rather than this one's.
    it "ignores claims with no resolved subject" do
      3.times { claim("Something happened.") }

      expect(described_class.review!(document)).to be_empty
    end

    it "needs a pattern to be part of before it reports isolation" do
      claim_about("Alec wrote.", "Alec")
      claim_about("Morticia arrived.", "Morticia")

      expect(described_class.review!(document)).to be_empty
    end
  end

  describe Sentinels::Orientation do
    let!(:orientation) { sentinel_for("orientation", "What enduring way of being emerges?", 7) }
    let(:reviewer) do
      Referent.create!(name: "Jeff", subject: "Person", role: "Reviewer", primitive: "person")
    end

    def flag_and_dispose(count, as:)
      count.times do |i|
        c = claim("claim #{i}")
        m = c.mentions.create!(text: "Subject#{i}")
        flag = Assertion.create!(asserter: sentinel, subject: m, act: "flag",
                                 claim: { "severity" => "stop", "message" => "…" })
        flag.dispose!(as: as, by: reviewer)
      end
    end

    # Chapter 7.4's fourth failure: governance that exists but evaluates nothing.
    it "reports a reviewer who let every flag stand" do
      flag_and_dispose(4, as: "accepted")

      flags = described_class.review!(document)

      expect(flags.sole.message).to include "let every one of them stand"
      expect(flags.sole.message).to include "not being weighed"
    end

    it "reports a reviewer who set every flag aside" do
      flag_and_dispose(4, as: "rejected")

      expect(described_class.review!(document).sole.message).to include "set every one of them aside"
    end

    it "stays quiet when the answers differ" do
      flag_and_dispose(3, as: "accepted")
      flag_and_dispose(2, as: "rejected")

      expect(described_class.review!(document)).to be_empty
    end

    # Below the threshold a uniform run is unremarkable, not a pattern.
    it "stays quiet below the threshold" do
      flag_and_dispose(3, as: "accepted")

      expect(described_class.review!(document)).to be_empty
    end
  end

  # A subject type missing from Document#flags is a flag nobody ever sees.
  it "surfaces flags about claims and about the document itself" do
    sentinel_for("agency", "What choices remain?", 2)
    sentinel_for("reflection", "Can this experience be viewed differently?", 4)
    ontological = ClaimCategory.create!(framework: framework, key: "ontological", name: "Ontological",
                                        position: 3, justification_rank: 3,
                                        definition: "…", confidence_source: "…")
    claim_about("Alec had no choice.", "Alec").classify!(ontological, asserter: sentinel)

    Sentinels::Agency.review!(document)
    Sentinels::Reflection.review!(document)

    subjects = document.flags.map { it.subject.class.name }
    expect(subjects).to include("Claim", "Document")
  end

  it "refuses to run any of them while identity is unresolved" do
    sentinel_for("agency", "What choices remain?", 2)
    c = claim("I saw Pugsley leave.")
    IdentitySentinel.verify!(c.mentions.create!(text: "Pugsley"))

    expect { DomainSentinel.review_all!(document) }.to raise_error(Document::ExecutionLocked)
  end
end
