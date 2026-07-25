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
end
