require "rails_helper"

# Deferred evaluation, pinned. The observer asks the same question the
# pair-scoped proposer asks — a conflict at this step, or none — with only the
# visible scope changed, which is what makes the two comparable.
RSpec.describe CaseObserver do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }

  before do
    admin = Referent.create!(name: "Admin", subject: "Person", role: "Admin", primitive: "person")
    model = LlmModel.find_by!(model_identifier: "gemini-2.5-pro")
    model.llm_provider.update!(status: "active")
    model.certify!(admin) unless model.certified?
    LlmAssignment.find_or_initialize_by(agent_pattern: described_class::OBSERVER,
                                        action_type: described_class::ACTION)
                 .update!(llm_model: model)
  end

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    c.classify!(category(kind), asserter: classifier, confidence: 0.9)
    c
  end

  let!(:claims) do
    [ claim("The camp is a game.", "interpretive"),
      claim("You earn points.", "observation"),
      claim("The prize is a tank.", "ontological"),
      claim("He never learned the truth.", "observation") ]
  end
  let(:kase) { Case.derive!(document).sole }
  let(:step) { Transition.create!(source: claims[0], target: claims[2]) }

  def client_returning(text)
    completion = LlmClients::Completion.new(text: text, input_tokens: 900, output_tokens: 40)
    Class.new { define_method(:complete) { |**| completion } }.new
  end

  def observe(payload)
    described_class.call(kase, step: step, client: client_returning(payload.to_json))
  end

  it "refuses a step that is not inside the case" do
    other = Document.create!(body: "…")
    elsewhere = Transition.create!(source: other.claims.create!(position: 1, text: "x"),
                                   target: other.claims.create!(position: 2, text: "y"))

    expect { described_class.call(kase, step: elsewhere, client: client_returning("{}")) }
      .to raise_error(described_class::OutsideCase)
  end

  it "shows the model the whole closed episode with the step marked" do
    seen = nil
    client = Class.new do
      define_method(:complete) do |system:, user:, **|
        seen = user
        LlmClients::Completion.new(text: { first: "none", second: "none", rationale: "r" }.to_json,
                                   input_tokens: 1, output_tokens: 1)
      end
    end.new

    described_class.call(kase, step: step, client: client)

    expect(seen).to include "He never learned the truth."
    expect(seen).to include ">> FROM"
    expect(seen).to include ">> TO"
  end

  it "returns the same shape the pair-scoped proposer returns, so the two compare" do
    reading = observe(first: "kindness", second: "truth", rationale: "the ending shows it")

    expect(reading).to be_a StepTensionProposer::Tension
    expect(reading.pair.map(&:key)).to eq %w[kindness truth]
    expect(reading).not_to be_none
  end

  it "takes none for an answer, which is the expected answer" do
    expect(observe(first: "none", second: "none", rationale: "no trade here")).to be_none
  end

  it "treats an unparseable answer as none rather than as a finding" do
    reading = described_class.call(kase, step: step, client: client_returning("not json"))

    expect(reading).to be_none
    expect(reading.rationale).to eq "unparseable"
  end

  it "treats a pair naming the same value twice as none" do
    expect(observe(first: "truth", second: "truth", rationale: "r")).to be_none
  end
end
