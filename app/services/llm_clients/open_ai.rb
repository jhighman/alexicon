module LlmClients
  # Raw HTTP against the Chat Completions API. Structured output via
  # response_format: json_schema with strict: true.
  #
  # NOT EXERCISED AGAINST THE LIVE API -- there is no OpenAI key on this
  # machine. Treat the first real call as the test.
  class OpenAI < Base
    ENDPOINT = "https://api.openai.com/v1/chat/completions".freeze

    def self.credential_env = "OPENAI_API_KEY"

    def complete(system:, user:, schema:, max_tokens:)
      body = { model: model.model_identifier, max_completion_tokens: max_tokens,
               messages: [ { role: "system", content: system },
                           { role: "user", content: user } ] }
      # A nil schema means prose was asked for; see LlmClients::Gemini.
      if schema
        body[:response_format] = { type: "json_schema",
                                   json_schema: { name: "classification", strict: true,
                                                  schema: schema } }
      end

      payload = post_json(ENDPOINT, body, headers: { "authorization" => "Bearer #{api_key}" })

      usage = payload["usage"] || {}
      Completion.new(text: payload.dig("choices", 0, "message", "content").to_s,
                     input_tokens: usage["prompt_tokens"].to_i,
                     output_tokens: usage["completion_tokens"].to_i)
    end
  end
end
