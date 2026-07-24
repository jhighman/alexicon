# Which providers this application can actually call.
#
# The registry may list any provider an admin wants to track, but only a
# provider with an adapter here is invocable. `LlmModel` refuses certification
# without one, so the registry can never promise a capability the code does not
# have — a registry that did would be the same failure it exists to prevent.
module LlmClients
  Completion = Data.define(:text, :input_tokens, :output_tokens)

  class MissingCredentials < StandardError; end
  class CallFailed < StandardError; end

  ADAPTERS = {
    "anthropic" => "LlmClients::Anthropic",
    "openai" => "LlmClients::OpenAI",
    "gemini" => "LlmClients::Gemini"
  }.freeze

  def self.for(provider_key) = ADAPTERS[provider_key]&.constantize

  def self.supported?(provider_key) = ADAPTERS.key?(provider_key)

  def self.supported_keys = ADAPTERS.keys
end
