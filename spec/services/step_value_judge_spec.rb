require "rails_helper"

# The third level, and the most easily misused thing in the system. Most of
# these specs are about what it refuses to do.
RSpec.describe StepValueJudge do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:sentinel) { Referent.find_by!(key: "governance-sentinel") }
  let(:judge) { Referent.find_by!(key: described_class::JUDGE) }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    c.classify!(category(kind), asserter: classifier, confidence: 0.9)
    c
  end

  def step(from_kind, to_kind, verdict: "unearned")
    a = claim("Recovering from my own.", from_kind)
    b = claim("These traps are getting everybody.", to_kind)
    t = Transition.create!(source: a, target: b)
    t.record_verdict!(verdict, asserter: sentinel) if verdict
    t
  end

  # Two commitments in conflict, as the proposer would have found them.
  def tension(first: "generality", second: "coherence")
    StepTensionProposer::Tension.new(
      first: FrameworkValue.find_by!(key: first), second: FrameworkValue.find_by!(key: second),
      rationale: "the second sentence widens the scope", none: false
    )
  end

  def rule_on(step, adapter_for: nil, **opts)
    described_class.call(step, tension: opts.fetch(:tension, tension()),
                               client: adapter_for || adapter)
  end

  # A stubbed adapter, so the guards can be tested without a model.
  def adapter(protects: "generality", confidence: 0.9)
    payload = { protects: protects, confidence: confidence,
                rationale: "the second sentence widens the scope" }
    completion = LlmClients::Completion.new(text: payload.to_json, input_tokens: 10,
                                            output_tokens: 20)
    instance_double(LlmClients::Base, complete: completion)
  end

  before do
    admin = Referent.create!(name: "Admin", subject: "Person", role: "Admin", primitive: "person")
    model = LlmModel.find_by!(model_identifier: "gemini-2.5-pro")
    model.llm_provider.update!(status: "active")
    model.certify!(admin) unless model.certified?
    LlmAssignment.find_or_initialize_by(agent_pattern: described_class::JUDGE,
                                        action_type: described_class::ACTION)
                 .update!(llm_model: model)
  end

  # THE guard. Inferring what somebody values from where their reasoning failed
  # is a short walk from psychologising them, and a promise in a prompt is not a
  # protection.
  describe "what it is a claim about" do
    it "asserts about the step, never about a person" do
      assertion = rule_on(step("interpretive", "ontological"))

      expect(assertion.subject).to be_a Transition
      expect(assertion.subject).not_to be_a Referent
    end

    it "cannot name a person as a subject, because it never chooses one" do
      assertion = rule_on(step("observation", "normative"))

      expect(Referent).not_to eq assertion.subject.class
      expect(assertion.claim.keys).to include "protects", "subordinates", "confidence", "rationale"
      expect(assertion.claim.keys).not_to include "person", "author", "asserter"
    end

    it "records the move it was reading, so the claim can be checked against it" do
      assertion = rule_on(step("interpretive", "normative"))

      expect(assertion.claim["move"]).to eq "interpretive -> normative"
    end

    # A value already knows what it is put before, so the model is not asked.
    it "takes what was subordinated from the vocabulary, not from the model" do
      assertion = rule_on(step("interpretive", "ontological"))
      value = FrameworkValue.find_by!(key: "generality")

      expect(assertion.claim["protects"]).to eq value.name
      expect(assertion.claim["subordinates"]).to eq value.subordinates
    end
  end

  describe "where it runs" do
    it "reads a step that was judged unearned" do
      expect(rule_on(step("interpretive", "ontological"))).to be_present
    end

    # It sits beneath a finding, not instead of one. Where an argument holds
    # there is nothing here to explain.
    it "refuses a step that was earned" do
      earned = step("interpretive", "objective", verdict: "earned")

      expect { rule_on(earned) }
        .to raise_error(described_class::NotFlagged, /not judged unearned/)
    end

    it "refuses a step nothing has ruled on" do
      unjudged = step("interpretive", "ontological", verdict: nil)

      expect { rule_on(unjudged) }
        .to raise_error described_class::NotFlagged
    end

    # The separation the Sentinel keeps from the classifier, kept again.
    it "refuses to read a step it ruled on itself" do
      t = step("interpretive", "ontological", verdict: nil)
      t.record_verdict!("unearned", asserter: judge)

      expect { rule_on(t) }
        .to raise_error(described_class::NotIndependent, /may not also read it/)
    end
  end

  describe "abstaining" do
    it "records nothing when the move reveals no commitment" do
      t = step("interpretive", "ontological")

      expect { rule_on(t, adapter_for: adapter(protects: "none")) }
        .not_to change { t.assertions.count }
    end

    it "records nothing below the confidence floor" do
      t = step("interpretive", "ontological")

      expect(rule_on(t, adapter_for: adapter(confidence: 0.8))).to be_nil
    end

    # The whole point of closing the list: it can pick or decline, never invent.
    it "discards a value that is not in the vocabulary" do
      t = step("interpretive", "ontological")

      expect(rule_on(t, adapter_for: adapter(protects: "the will to power"))).to be_nil
    end

    # Higher than the classifier's: a weak reading of a category is still a
    # category; a weak reading of what somebody was protecting is worse.
    it "sets its floor above the classifier's" do
      expect(described_class::DEFAULT_CONFIDENCE_FLOOR)
        .to be > ClaimClassifier::DEFAULT_CONFIDENCE_FLOOR
    end
  end

  # A framework carries its own values, and what a step protects only means
  # something relative to a list of things it could have protected.
  describe "a different vocabulary" do
    it "reads against the list it was given" do
      other = Framework.create!(key: "other-fw", name: "Other", version: "1", current: false)
      domain = Domain.create!(framework: other, key: "motivation", name: "Motivation",
                              position: 1, question: "Why?")
      DomainComponent.create!(domain: domain, name: "Values", position: 1)
      FrameworkValue.create!(framework: other, domain: domain, key: "productiveness",
                             name: "Productiveness", definition: "Creating value.",
                             subordinates: "Consuming without creating.", provenance: "proposed")

      second = FrameworkValue.create!(framework: other, domain: domain, key: "prudence",
                                      name: "Prudence", definition: "Weighing before acting.",
                                      subordinates: "Speed.", provenance: "proposed")
      other_tension = StepTensionProposer::Tension.new(
        first: FrameworkValue.find_by!(framework: other, key: "productiveness"),
        second: second, rationale: "the move trades one for the other", none: false
      )

      assertion = described_class.call(step("interpretive", "ontological"),
                                       tension: other_tension,
                                       client: adapter(protects: "productiveness"))

      expect(assertion.claim["protects"]).to eq "Productiveness"
      expect(assertion.claim["vocabulary"]).to eq "other-fw"
      expect(assertion.claim["against"]).to eq "Prudence"
    end

    # The precondition the whole repair turns on: no conflict, no ruling.
    it "refuses to rule where nothing was found in conflict" do
      none = StepTensionProposer::Tension.new(first: nil, second: nil,
                                              rationale: "an aside", none: true)

      expect { described_class.call(step("interpretive", "ontological"), tension: none) }
        .to raise_error(described_class::NoTension, /nothing was found in conflict/)
    end

    it "refuses to rule with no tension at all" do
      expect { described_class.call(step("interpretive", "ontological"), tension: nil) }
        .to raise_error described_class::NoTension
    end
  end

  describe "the reading it records" do
    it "carries its confidence, always" do
      assertion = rule_on(step("observation", "normative"))

      expect(assertion.claim["confidence"]).to eq 0.9
      expect(assertion.claim["rationale"]).to be_present
      expect(assertion.claim["vocabulary"]).to eq Framework.current!.key
    end

    it "is attributed to a judge separate from the Sentinel and the classifier" do
      assertion = rule_on(step("interpretive", "ontological"))

      expect(assertion.asserter).to eq judge
      expect(assertion.asserter).not_to eq sentinel
      expect(assertion.asserter).not_to eq classifier
    end

    it "does not disturb the verdict it was asked about" do
      t = step("interpretive", "ontological")
      rule_on(t)

      expect(t.reload.verdict.to_s).to eq "unearned"
    end
  end

  describe "across a document" do
    # A step where no conflict is found is passed over entirely, which is the
    # expected outcome for most of them.
    it "passes over a step with no tension, without asking the judge at all" do
      step("interpretive", "ontological")
      none = StepTensionProposer::Tension.new(first: nil, second: nil, rationale: "-", none: true)
      allow(StepTensionProposer).to receive(:call).and_return(none)

      expect(described_class.for_document(document.reload, client: adapter)).to be_empty
    end

    it "reads every unearned step and leaves the others alone" do
      step("interpretive", "ontological")
      step("observation", "normative")
      step("interpretive", "objective", verdict: "earned")

      allow(StepTensionProposer).to receive(:call).and_return(tension)

      readings = described_class.for_document(document.reload, client: adapter)

      expect(readings.size).to eq 2
    end

    it "does not read a step twice" do
      allow(StepTensionProposer).to receive(:call).and_return(tension)
      step("interpretive", "ontological")
      described_class.for_document(document.reload, client: adapter)

      expect(described_class.for_document(document.reload, client: adapter)).to be_empty
    end
  end
end
