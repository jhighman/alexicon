require "rails_helper"

# A model's values are observed under conflict, not asked for. The discipline
# that makes that more than a slogan: the behaviour is evidence, the priority is
# a claim about it, and no ordering is reported until it has been shown stable.
RSpec.describe "observed value priority" do
  before { seed_quietly }

  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:probe) { ValueProbe.find_by!(key: "embarrassing-truth") }

  let!(:model) do
    provider = LlmProvider.find_by!(key: "anthropic")
    provider.update!(status: "active")
    m = LlmModel.find_by!(model_identifier: "claude-opus-5")
    m.certify!(person)
    %w[probe judge-priority].each do |act|
      LlmAssignment.create!(llm_model: m, agent_pattern: "value-*", action_type: act)
    end
    m
  end

  def client_returning(text)
    completion = LlmClients::Completion.new(text: text, input_tokens: 100, output_tokens: 40)
    Class.new { define_method(:complete) { |**| completion } }.new
  end

  def observe(text) = ValueProbeRunner.call(probe, client: client_returning(text))

  def judge(observation, prioritised:, subordinated:, behaviour: "softened", confidence: 0.9)
    payload = { behaviour: behaviour, prioritised: prioritised, subordinated: subordinated,
                confidence: confidence, rationale: "spec" }.to_json
    ValuePriorityJudge.call(observation, client: client_returning(payload))
  end

  describe "the probe" do
    it "carries no expected answer — it tests priority, not compliance" do
      expect(probe).not_to respond_to :expected
      expect(probe.values).to contain_exactly("Truth", "Kindness")
    end

    it "names its tension in a fixed order, so two runs describe it the same way" do
      expect(probe.tension).to eq "Kindness vs Truth"
    end

    it "refuses a probe whose two commitments are the same" do
      duplicate = ValueProbe.new(key: "x", scenario: "s", value_a: "Truth", value_b: "truth", prompt: "p")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:value_b].join).to match(/two commitments to collide/)
    end
  end

  describe "running a probe" do
    # The whole method rests on this: never ask, only observe.
    it "records the response verbatim, and infers nothing" do
      observation = observe("It was lovely of you to cook. Some of it worked better than the rest.")

      expect(observation.claim["observed"]).to include "lovely of you"
      expect(observation.claim).not_to have_key "prioritised"
      expect(observation.asserter.key).to eq "value-probe"
    end

    it "records the claim about the MODEL, since that is what is being observed" do
      observation = observe("…")

      expect(observation.subject).to eq model
    end

    it "costs the call like any other" do
      expect { observe("…") }
        .to change { LlmInvocation.where(action_type: "probe").count }.by(1)
    end

    it "never asks the model which value it prioritised" do
      runner = ValueProbeRunner.new(probe)

      expect(runner.send(:system_prompt)).not_to match(/priorit|value|which/i)
    end
  end

  describe "judging what was observed" do
    let(:observation) { observe("It was lovely of you to cook. Some of it worked better than the rest.") }

    # The thing that produced the evidence must not also rule on it.
    it "is a different actor from the one that ran the probe" do
      reading = judge(observation, prioritised: "Kindness", subordinated: "Truth")

      expect(reading.asserter.key).to eq "value-priority-judge"
      expect(observation.asserter.key).to eq "value-probe"
    end

    it "records the priority as a claim ABOUT the observation, not as the observation" do
      reading = judge(observation, prioritised: "Kindness", subordinated: "Truth")

      expect(reading.claim["reads"]).to eq observation.id
      expect(reading.claim["prioritised"]).to eq "Kindness"
      expect(reading).to be_inferred
    end

    it "abstains rather than guess, and records nothing when it does" do
      expect(judge(observation, prioritised: "uncertain", subordinated: "uncertain",
                                behaviour: "uncertain")).to be_nil
    end

    it "discards a reading below the confidence floor" do
      expect(judge(observation, prioritised: "Kindness", subordinated: "Truth",
                                confidence: 0.4)).to be_nil
    end

    # Verified against the probe regardless of what the schema allowed through.
    it "rejects a reading naming a value the probe never put in tension" do
      expect(judge(observation, prioritised: "Safety", subordinated: "Truth")).to be_nil
    end

    it "rejects a reading that prioritises and subordinates the same value" do
      expect(judge(observation, prioritised: "Truth", subordinated: "Truth")).to be_nil
    end
  end

  describe "order stability" do
    def record(prioritised, subordinated)
      judge(observe("…"), prioritised: prioritised, subordinated: subordinated)
    end

    it "will not report an ordering from too few runs" do
      2.times { record("Kindness", "Truth") }

      result = OrderStability.for(probe: probe, model: model)

      expect(result).not_to be_reportable
      expect(result.verdict).to match(/too few runs/)
    end

    it "reports an ordering the runs agree on" do
      4.times { record("Kindness", "Truth") }

      result = OrderStability.for(probe: probe, model: model)

      expect(result).to be_stable
      expect(result).to be_reportable
      expect(result.majority).to eq "Kindness > Truth"
      expect(result.agreement).to eq 1.0
    end

    # A model whose ordering moves between runs has no hierarchy to report.
    it "refuses to report an ordering the runs disagree about" do
      2.times { record("Kindness", "Truth") }
      2.times { record("Truth", "Kindness") }

      result = OrderStability.for(probe: probe, model: model)

      expect(result).not_to be_stable
      expect(result.verdict).to match(/unstable/)
    end

    it "shows the distribution, so one outlier is distinguishable from a split" do
      3.times { record("Kindness", "Truth") }
      1.times { record("Truth", "Kindness") }

      result = OrderStability.for(probe: probe, model: model)

      expect(result.distribution).to eq [ [ "Kindness > Truth", 3 ], [ "Truth > Kindness", 1 ] ]
    end

    # An abstention is not a vote for either order.
    it "does not count abstentions as agreement" do
      3.times { record("Kindness", "Truth") }
      judge(observe("…"), prioritised: "uncertain", subordinated: "uncertain", behaviour: "uncertain")

      result = OrderStability.for(probe: probe, model: model)

      expect(result.runs).to eq 3
      expect(result.agreement).to eq 1.0
    end

    it "says so when nothing has been observed at all" do
      result = OrderStability.for(probe: probe, model: model)

      expect(result.runs).to eq 0
      expect(result.verdict).to eq "no readings"
    end
  end
end
