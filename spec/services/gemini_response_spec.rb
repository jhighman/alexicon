require "rails_helper"

# A truncated answer must never be returned as an answer. Gemini charges its
# thinking against maxOutputTokens, so a call can spend almost the whole budget
# reasoning and emit half a JSON document. Handed back as a Completion it parses
# as nothing, and the caller records a successful call that produced no
# judgements -- a silent loss.
RSpec.describe "a cut-off response" do
  let(:provider) { LlmProvider.create!(key: "gemini", name: "Google Gemini") }
  let(:model) do
    LlmModel.create!(llm_provider: provider, model_identifier: "gemini-2.5-pro",
                     display_name: "Gemini 2.5 Pro")
  end
  let(:adapter) { LlmClients::Gemini.new(model) }

  def payload(reason, thoughts: 3830)
    { "candidates" => [ { "finishReason" => reason,
                          "content" => { "parts" => [ { "text" => '{"proposals":[{"na' } ] } } ],
      "usageMetadata" => { "promptTokenCount" => 5113, "candidatesTokenCount" => 251,
                           "thoughtsTokenCount" => thoughts } }
  end

  it "refuses rather than handing back half a document" do
    expect { adapter.send(:check_finished, payload("MAX_TOKENS"), payload("MAX_TOKENS")["usageMetadata"]) }
      .to raise_error(LlmClients::ResponseTruncated, /cut off at the token limit/)
  end

  it "says how the budget was spent, since that is what has to change" do
    expect { adapter.send(:check_finished, payload("MAX_TOKENS"), payload("MAX_TOKENS")["usageMetadata"]) }
      .to raise_error(LlmClients::ResponseTruncated) { |e|
        expect(e.message).to include "3830 spent thinking"
        expect(e.message).to include "251 written"
      }
  end

  it "is not retryable — the same request is cut off in the same place" do
    expect(LlmClients::ResponseTruncated.ancestors).not_to include LlmClients::Retryable
  end

  it "reports any other early stop rather than ignoring it" do
    expect { adapter.send(:check_finished, payload("SAFETY"), {}) }
      .to raise_error(LlmClients::RequestRejected, /stopped early: SAFETY/)
  end

  it "passes a complete answer through" do
    expect { adapter.send(:check_finished, payload("STOP"), {}) }.not_to raise_error
  end

  # Nested objects inside an array's items were rejected outright: the cleaner
  # only stripped the top level.
  it "strips additionalProperties at every depth" do
    schema = { type: "object", additionalProperties: false,
               properties: { rows: { type: "array",
                                     items: { type: "object", additionalProperties: false,
                                              properties: { a: { type: "string" } } } } } }

    cleaned = adapter.send(:gemini_schema, schema)

    expect(JSON.generate(cleaned)).not_to include "additionalProperties"
    expect(cleaned.dig(:properties, :rows, :items, :propertyOrdering)).to eq [ "a" ]
  end

  # The value probes ask for a natural answer. Forcing JSON anyway would put the
  # adapter's assumption in front of what the caller asked for.
  describe "when no schema is given" do
    before { allow(adapter).to receive(:api_key).and_return("test-key") }

    it "does not demand JSON" do
      sent = nil
      allow(adapter).to receive(:post_json) { |_url, body| sent = body; payload("STOP") }

      adapter.complete(system: "s", user: "u", schema: nil, max_tokens: 100)

      expect(sent[:generationConfig]).not_to have_key :responseMimeType
      expect(sent[:generationConfig]).not_to have_key :responseSchema
    end

    it "still demands JSON when a schema is given" do
      sent = nil
      allow(adapter).to receive(:post_json) { |_url, body| sent = body; payload("STOP") }

      adapter.complete(system: "s", user: "u", schema: { type: "object" }, max_tokens: 100)

      expect(sent[:generationConfig][:responseMimeType]).to eq "application/json"
    end
  end

  # Every other adapter treats max_tokens as the size of the ANSWER. Without a
  # floor here the same number means different things depending on which
  # provider a governed decision happened to route to.
  describe "thinking headroom" do
    before { allow(adapter).to receive(:api_key).and_return("test-key") }

    def sent_config(max_tokens)
      sent = nil
      allow(adapter).to receive(:post_json) { |_url, body| sent = body; payload("STOP") }
      adapter.complete(system: "s", user: "u", schema: nil, max_tokens: max_tokens)
      sent[:generationConfig]
    end

    it "asks for the answer the caller wanted plus room to think" do
      expect(sent_config(1024)[:maxOutputTokens])
        .to eq 1024 + LlmClients::Gemini::THINKING_HEADROOM
    end

    it "covers the thinking actually observed in the failures that prompted it" do
      # ~950 on a two-line prompt, ~1,500 on a scenario, ~3,800 on a document.
      expect(LlmClients::Gemini::THINKING_HEADROOM).to be >= 3_830
    end

    # A floor, not a guarantee.
    it "still refuses a truncated answer, and names the headroom it allowed" do
      expect { adapter.send(:check_finished, payload("MAX_TOKENS"), payload("MAX_TOKENS")["usageMetadata"]) }
        .to raise_error(LlmClients::ResponseTruncated, /of headroom allowed/)
    end
  end
end
