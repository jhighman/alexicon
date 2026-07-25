module LlmClients
  # Raw HTTP against generateContent. Structured output via
  # responseMimeType + responseSchema.
  #
  # Exercised against the live API on 25 Jul 2026: five classifications, all
  # successful. The schema translation below is the part that had to be right.
  class Gemini < Base
    def self.credential_env = "GEMINI_API_KEY"

    # This model thinks before it writes, and the thinking is charged against
    # maxOutputTokens. Every other adapter treats `max_tokens` as the size of
    # the ANSWER, so without this the same number means different things
    # depending on which provider a governed decision happened to route to --
    # and the caller would have to know which providers think, which is exactly
    # what the adapter layer exists to hide.
    #
    # Observed thinking: ~950 on a two-line prompt, ~1,500 on a short scenario,
    # ~3,800 on a whole document. Three separate services were sized wrong
    # before this existed, each discovered by a run failing.
    #
    # It is a floor, not a guarantee. The finishReason check still fires if the
    # thinking outgrows even this, and says so.
    THINKING_HEADROOM = 4_096

    def complete(system:, user:, schema:, max_tokens:)
      config = { maxOutputTokens: max_tokens + THINKING_HEADROOM }
      # A nil schema means prose was asked for. Demanding JSON anyway would put
      # the adapter's assumption in front of what the caller wanted -- and the
      # value probes need a natural answer, not a structured one.
      if schema
        config[:responseMimeType] = "application/json"
        config[:responseSchema] = gemini_schema(schema)
      end

      payload = post_json(endpoint, {
        systemInstruction: { parts: [ { text: system } ] },
        contents: [ { role: "user", parts: [ { text: user } ] } ],
        generationConfig: config
      })

      usage = payload["usageMetadata"] || {}
      check_finished(payload, usage)

      Completion.new(text: payload.dig("candidates", 0, "content", "parts", 0, "text").to_s,
                     input_tokens: usage["promptTokenCount"].to_i,
                     output_tokens: usage["candidatesTokenCount"].to_i)
    end

    private

    # A truncated answer must never be returned as an answer.
    #
    # This model thinks before it writes, and the thinking is charged against
    # maxOutputTokens: one call spent 3,830 tokens of a 4,096 budget thinking
    # and 251 writing, so the JSON stopped mid-object. Handed back as a
    # Completion it parsed as nothing, and the caller recorded a successful
    # call that produced no judgements -- a silent loss, which is the one
    # outcome this project exists to prevent.
    def check_finished(payload, usage)
      reason = payload.dig("candidates", 0, "finishReason").to_s
      return if reason.blank? || reason == "STOP"

      if reason == "MAX_TOKENS"
        thoughts = usage["thoughtsTokenCount"].to_i
        raise ResponseTruncated,
              "the answer was cut off at the token limit " \
              "(#{usage['candidatesTokenCount'].to_i} written, #{thoughts} spent thinking, " \
              "#{THINKING_HEADROOM} of headroom allowed). Ask for fewer items per call, " \
              "or raise THINKING_HEADROOM."
      end

      raise RequestRejected, "the provider stopped early: #{reason}"
    end

    def endpoint
      "https://generativelanguage.googleapis.com/v1beta/models/" \
        "#{model.model_identifier}:generateContent?key=#{api_key}"
    end

    # Gemini's schema dialect rejects additionalProperties and wants an explicit
    # propertyOrdering.
    #
    # Applied at every depth, not just the top. The first schema sent through
    # here was flat, so a top-level strip looked sufficient; the first nested one
    # -- objects inside an array's items -- was rejected outright with
    # "Unknown name additionalProperties at properties[0].value.items".
    def gemini_schema(node)
      case node
      when Array then node.map { gemini_schema(it) }
      when Hash
        cleaned = node.except(:additionalProperties, "additionalProperties")
                      .transform_values { gemini_schema(it) }
        properties = cleaned[:properties] || cleaned["properties"]
        cleaned[:propertyOrdering] = properties.keys.map(&:to_s) if properties.is_a?(Hash)
        cleaned
      else node
      end
    end
  end
end
