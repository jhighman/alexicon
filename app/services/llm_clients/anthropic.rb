module LlmClients
  # Uses the official Anthropic SDK. Structured output via output_config.format.
  class Anthropic < Base
    def self.credential_env = "ANTHROPIC_API_KEY"

    def complete(system:, user:, schema:, max_tokens:)
      params = { model: model.model_identifier, max_tokens: max_tokens, system: system,
                 messages: [ { role: "user", content: user } ] }
      # A nil schema means prose was asked for; see LlmClients::Gemini.
      if schema
        params[:output_config] = { format: { type: "json_schema", schema: schema },
                                   effort: "medium" }
      end

      response = client.messages.create(**params)

      block = Array(response.content).find { it.type.to_s == "text" }
      Completion.new(text: block&.text.to_s,
                     input_tokens: response.usage&.input_tokens.to_i,
                     output_tokens: response.usage&.output_tokens.to_i)
    rescue ::Anthropic::Errors::Error => e
      raise translate(e)
    end

    private

    # The SDK has its own error hierarchy; callers get the neutral one, so
    # nothing upstream has to know which vendor it happened to be talking to.
    def translate(error)
      case error
      when ::Anthropic::Errors::RateLimitError
        RateLimited.new(error.message, retry_after: nil)
      when ::Anthropic::Errors::InternalServerError, ::Anthropic::Errors::APIConnectionError,
           ::Anthropic::Errors::APITimeoutError
        (error.is_a?(::Anthropic::Errors::InternalServerError) ? ServerError : ConnectionFailed)
          .new(error.message)
      when ::Anthropic::Errors::AuthenticationError, ::Anthropic::Errors::PermissionDeniedError
        MissingCredentials.new(error.message)
      else
        RequestRejected.new(error.message)
      end
    end

    def client = @client ||= ::Anthropic::Client.new(api_key: api_key)
  end
end
