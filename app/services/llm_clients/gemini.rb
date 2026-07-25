module LlmClients
  # Raw HTTP against generateContent. Structured output via
  # responseMimeType + responseSchema.
  #
  # Exercised against the live API on 25 Jul 2026: five classifications, all
  # successful. The schema translation below is the part that had to be right.
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
