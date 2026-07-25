# Which providers this application can actually call.
#
# The registry may list any provider an admin wants to track, but only a
# provider with an adapter here is invocable. `LlmModel` refuses certification
# without one, so the registry can never promise a capability the code does not
# have — a registry that did would be the same failure it exists to prevent.
module LlmClients
  Completion = Data.define(:text, :input_tokens, :output_tokens)

  class MissingCredentials < StandardError; end

  # A call failed. Every adapter reports failure in these terms rather than in
  # its vendor's, because the decision that depends on them -- retry, or stop --
  # is the same whoever was on the other end. A caller that had to know which
  # SDK raised would be a caller that quietly only handles one provider, which
  # is the bug this taxonomy exists to prevent.
  class CallFailed < StandardError; end

  # Worth trying again: the request was fine, the moment was not.
  class Retryable < CallFailed
    # Seconds the provider asked us to wait, when it said.
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil)
      super(message)
      @retry_after = retry_after
    end
  end

  class RateLimited < Retryable; end
  class ServerError < Retryable; end
  class ConnectionFailed < Retryable; end

  # Not worth trying again: a bad request, a rejected key, a refused model.
  # Retrying these burns quota to arrive at the same answer.
  class RequestRejected < CallFailed; end

  # The answer was cut off at the token limit. Not retryable as-is -- the same
  # request will be cut off in the same place -- and emphatically not something
  # to parse anyway: half a JSON document reads as an empty one.
  class ResponseTruncated < CallFailed; end

  ADAPTERS = {
    "anthropic" => "LlmClients::Anthropic",
    "openai" => "LlmClients::OpenAI",
    "gemini" => "LlmClients::Gemini"
  }.freeze

  def self.for(provider_key) = ADAPTERS[provider_key]&.constantize

  def self.supported?(provider_key) = ADAPTERS.key?(provider_key)

  def self.supported_keys = ADAPTERS.keys
end
