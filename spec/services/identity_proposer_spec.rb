require "rails_helper"

# The model knows who Polanyi is; the regex never will. What the model must not
# do is decide -- a proposal waits for a person, and the Sentinel keeps
# refusing until one answers.
RSpec.describe IdentityProposer do
  before { seed_quietly }

  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:document) { Document.create!(body: "Polanyi wrote it. Fortunately I read it.") }

  let!(:model) do
    provider = LlmProvider.find_by!(key: "anthropic")
    provider.update!(status: "active")
    m = LlmModel.find_by!(model_identifier: "claude-opus-5")
    m.certify!(person)
    LlmAssignment.create!(llm_model: m, agent_pattern: "identity-proposer", action_type: "resolve")
    m
  end

  def stub_client(payload)
    completion = LlmClients::Completion.new(text: payload.to_json, input_tokens: 900, output_tokens: 120)
    Class.new { define_method(:complete) { |**| completion } }.new
  end

  def ingest!
    DocumentIngest.call(document)
    document.reload
  end

  let(:answer) do
    { proposals: [
      { name: "Polanyi", kind: "subject", subject: "Person", role: "Philosopher",
        confidence: 0.95, rationale: "cited as the author of a maxim about tacit knowledge" },
      { name: "Fortunately", kind: "not_a_subject", subject: "", role: "",
        confidence: 0.99, rationale: "sentence-initial adverb" }
    ] }
  end

  it "records a proposal for each unresolved name" do
    ingest!

    recorded = described_class.new(document, client: stub_client(answer)).call

    expect(recorded.map { it.claim["name"] }).to contain_exactly("Polanyi", "Fortunately")
    expect(recorded.map(&:asserter).map(&:key).uniq).to eq [ "identity-proposer" ]
  end

  # The whole point. A proposal is inference awaiting a person.
  it "does not resolve anything or lift the lock" do
    ingest!
    stops_before = document.open_stops.count

    described_class.new(document, client: stub_client(answer)).call

    document.reload
    expect(document.open_stops.count).to eq stops_before
    expect(document).not_to be_executable
    expect(document.mentions.map(&:status)).not_to include "resolved"
  end

  it "is a different actor from the Sentinel that would accept it" do
    ingest!

    described_class.new(document, client: stub_client(answer)).call

    proposer = Referent.find_by!(key: "identity-proposer")
    expect(proposer.key).not_to eq "identity-sentinel"
    expect(document.mentions.filter_map(&:identity_proposal).map(&:asserter).uniq).to eq [ proposer ]
  end

  it "records the call like any other" do
    ingest!

    expect { described_class.new(document, client: stub_client(answer)).call }
      .to change { LlmInvocation.where(action_type: "resolve").count }.by(1)

    invocation = LlmInvocation.order(:created_at).last
    expect(invocation.agent.key).to eq "identity-proposer"
    expect(invocation.status).to eq "success"
  end

  describe "refusing to invent" do
    it "records nothing for a name it does not recognise" do
      ingest!
      unsure = { proposals: [ { name: "Polanyi", kind: "unknown", subject: "", role: "",
                                confidence: 0.2, rationale: "no idea" } ] }

      recorded = described_class.new(document, client: stub_client(unsure)).call

      expect(recorded).to be_empty
    end

    # A half-passport is no anchor, so it is treated as abstention rather than
    # written down as a weaker one.
    it "downgrades a subject with an incomplete passport to abstention" do
      ingest!
      partial = { proposals: [ { name: "Polanyi", kind: "subject", subject: "Person", role: "",
                                 confidence: 0.9, rationale: "a person of some kind" } ] }

      expect(described_class.new(document, client: stub_client(partial)).call).to be_empty
    end

    it "ignores a name it was never asked about" do
      ingest!
      invented = { proposals: [ { name: "Napoleon", kind: "subject", subject: "Person", role: "Emperor",
                                  confidence: 0.99, rationale: "made up" } ] }

      expect(described_class.new(document, client: stub_client(invented)).call).to be_empty
    end

    it "fails closed on unparseable output" do
      ingest!
      broken = Class.new do
        define_method(:complete) do |**|
          LlmClients::Completion.new(text: "not json", input_tokens: 1, output_tokens: 1)
        end
      end.new

      expect(described_class.new(document, client: broken).call).to be_empty
    end
  end

  it "asks about each name once, however often it appears" do
    document.update!(body: "Polanyi wrote it. Polanyi meant it. Polanyi was right.")
    ingest!

    asked = described_class.new(document, client: stub_client(answer)).send(:unresolved_names)

    expect(asked).to eq [ "Polanyi" ]
    expect(document.open_stops.count).to eq 3
  end
end
