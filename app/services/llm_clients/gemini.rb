module LlmClients
  # Raw HTTP against generateContent. Structured output via
  # responseMimeType + responseSchema.
  #
  # NOT EXERCISED AGAINST THE LIVE API -- there is no Gemini key on this
  # machine. Treat the first real call as the test.
  class Gemini < Base
    def self.credential_env = "GEMINI_API_KEY"

    def complete(system:, user:, schema:, max_tokens:)
      payload = post_json(endpoint, {
        systemInstruction: { parts: [ { text: system } ] },
        contents: [ { role: "user", parts: [ { text: user } ] } ],
        generationConfig: {
          maxOutputTokens: max_tokens,
          responseMimeType: "application/json",
          responseSchema: gemini_schema(schema)
        }
      })

      usage = payload["usageMetadata"] || {}
      Completion.new(text: payload.dig("candidates", 0, "content", "parts", 0, "text").to_s,
                     input_tokens: usage["promptTokenCount"].to_i,
                     output_tokens: usage["candidatesTokenCount"].to_i)
    end

    private

    def endpoint
      "https://generativelanguage.googleapis.com/v1beta/models/" \
        "#{model.model_identifier}:generateContent?key=#{api_key}"
    end

    # Gemini's schema dialect rejects additionalProperties and wants an
    # explicit propertyOrdering.
    def gemini_schema(schema)
      cleaned = schema.deep_dup
      cleaned.delete(:additionalProperties)
      cleaned.delete("additionalProperties")
      cleaned[:propertyOrdering] = cleaned[:properties]&.keys&.map(&:to_s)
      cleaned
    end
  end
end
