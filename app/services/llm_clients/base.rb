# The interface every provider adapter satisfies.
#
# An adapter turns the classifier's one request shape -- system prompt, user
# text, JSON schema -- into whatever the provider expects, and returns a
# Completion. Structured output is not optional: the classifier's guarantee
# that a category is one of four depends on the provider enforcing the schema.
module LlmClients
  class Base
    # Each adapter names the environment variable it falls back to, so the UI
    # can tell an admin what to export if no key is stored.
    def self.credential_env = raise(NotImplementedError)

    def initialize(model)
      @model = model
    end

    # Returns a Completion. Implementations must request structured output
    # against `schema` -- the classifier's guarantees depend on it.
    def complete(system:, user:, schema:, max_tokens:) = raise(NotImplementedError)

    private

    attr_reader :model

    # The key comes from the provider record -- stored if an admin set one,
    # otherwise the environment. The adapter does not decide which.
    def api_key
      key = model.llm_provider.api_key_in_effect
      if key.blank?
        raise MissingCredentials,
              "no key for #{model.llm_provider.name}: set one at /llm_providers " \
              "or export #{self.class.credential_env}"
      end

      key
    end

    def post_json(url, body, headers: {})
      uri = URI(url)
      request = Net::HTTP::Post.new(uri, { "content-type" => "application/json" }.merge(headers))
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                                 open_timeout: 15, read_timeout: 120) do |http|
        http.request(request)
      end

      raise_for_status(response) unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED,
           EOFError, SocketError, IOError => e
      raise ConnectionFailed, "#{e.class}: #{e.message}"
    end

    # HTTP already distinguishes "later" from "no". Adapters that speak raw HTTP
    # get that distinction for free; the only thing to avoid is throwing it away.
    def raise_for_status(response)
      detail = "#{response.code}: #{response.body.to_s.truncate(300)}"
      after = retry_after_seconds(response)

      case response.code.to_i
      when 429 then raise RateLimited.new(detail, retry_after: after)
      when 500..599 then raise ServerError.new(detail, retry_after: after)
      else raise RequestRejected, detail
      end
    end

    # Retry-After is either seconds or an HTTP date.
    def retry_after_seconds(response)
      raw = response["retry-after"]
      return nil if raw.blank?
      return raw.to_i if raw.match?(/\A\d+\z/)

      seconds = (Time.httpdate(raw) - Time.current).ceil
      seconds.positive? ? seconds : nil
    rescue ArgumentError
      nil
    end
  end
end
