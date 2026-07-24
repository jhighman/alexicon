# The interface every provider adapter satisfies.
#
# An adapter turns the classifier's one request shape -- system prompt, user
# text, JSON schema -- into whatever the provider expects, and returns a
# Completion. Structured output is not optional: the classifier's guarantee
# that a category is one of four depends on the provider enforcing the schema.
module LlmClients
  class Base
    # Each adapter names the environment variable holding its key, so the UI
    # can report which providers are actually usable right now.
    def self.credential_env = raise(NotImplementedError)

    def self.credentialed? = ENV[credential_env].present?

    def initialize(model)
      @model = model
    end

    # Returns a Completion. Implementations must request structured output
    # against `schema` -- the classifier's guarantees depend on it.
    def complete(system:, user:, schema:, max_tokens:) = raise(NotImplementedError)

    private

    attr_reader :model

    def api_key
      key = ENV[self.class.credential_env]
      raise MissingCredentials, "#{self.class.credential_env} is not set" if key.blank?

      key
    end

    def post_json(url, body, headers: {})
      uri = URI(url)
      request = Net::HTTP::Post.new(uri, { "content-type" => "application/json" }.merge(headers))
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
        http.request(request)
      end

      raise CallFailed, "#{response.code}: #{response.body.to_s.truncate(300)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
