require "rails_helper"

# Every adapter reports failure in the same terms, because the decision that
# depends on them -- wait and retry, or stop -- is the same whoever was on the
# other end. This is the seam where a vendor-specific rule stopped working the
# moment a second provider was routed to.
RSpec.describe "adapter error taxonomy" do
  let(:provider) { LlmProvider.create!(key: "gemini", name: "Google Gemini") }
  let(:model) do
    LlmModel.create!(llm_provider: provider, model_identifier: "gemini-2.5-pro",
                     display_name: "Gemini 2.5 Pro")
  end
  let(:adapter) { LlmClients::Gemini.new(model) }

  def respond(code, body: "{}", headers: {})
    klass = Net::HTTPResponse::CODE_TO_OBJ[code.to_s]
    response = klass.new("1.1", code.to_s, "")
    allow(response).to receive_messages(body: body, code: code.to_s)
    headers.each { |k, v| response[k] = v }
    response
  end

  describe "HTTP status" do
    {
      429 => LlmClients::RateLimited,
      500 => LlmClients::ServerError,
      503 => LlmClients::ServerError,
      400 => LlmClients::RequestRejected,
      404 => LlmClients::RequestRejected
    }.each do |code, expected|
      it "maps #{code} to #{expected.name.demodulize}" do
        expect { adapter.send(:raise_for_status, respond(code)) }.to raise_error(expected)
      end
    end

    # The distinction that matters: one of these is worth waiting out.
    it "marks throttling and outages as retryable, and a bad request as not" do
      expect(LlmClients::RateLimited.ancestors).to include LlmClients::Retryable
      expect(LlmClients::ServerError.ancestors).to include LlmClients::Retryable
      expect(LlmClients::RequestRejected.ancestors).not_to include LlmClients::Retryable
    end
  end

  describe "Retry-After" do
    # Returns the raised error, and fails loudly if nothing was raised -- a
    # bare `rescue` in an example passes when the code under test does nothing.
    def rate_limit_with(header)
      adapter.send(:raise_for_status, respond(429, headers: header))
      raise "expected raise_for_status to raise, but it returned"
    rescue LlmClients::RateLimited => e
      e
    end

    it "reads a plain number of seconds" do
      expect(rate_limit_with("retry-after" => "30").retry_after).to eq 30
    end

    it "reads an HTTP date" do
      error = rate_limit_with("retry-after" => 45.seconds.from_now.httpdate)

      expect(error.retry_after).to be_between(40, 46)
    end

    it "is simply absent when the provider did not say" do
      expect(rate_limit_with({}).retry_after).to be_nil
    end

    it "ignores a date that has already passed rather than waiting a negative time" do
      expect(rate_limit_with("retry-after" => 1.hour.ago.httpdate).retry_after).to be_nil
    end

    it "ignores an unparseable value instead of raising over it" do
      expect(rate_limit_with("retry-after" => "soonish").retry_after).to be_nil
    end
  end

  describe "the Anthropic SDK" do
    let(:anthropic_provider) { LlmProvider.create!(key: "anthropic", name: "Anthropic") }
    let(:anthropic_model) do
      LlmModel.create!(llm_provider: anthropic_provider, model_identifier: "claude-opus-5",
                       display_name: "Claude Opus 5")
    end
    let(:anthropic) { LlmClients::Anthropic.new(anthropic_model) }

    it "translates its own hierarchy into the neutral one" do
      expect(anthropic.send(:translate, Anthropic::Errors::RateLimitError.allocate))
        .to be_a LlmClients::RateLimited
      expect(anthropic.send(:translate, Anthropic::Errors::InternalServerError.allocate))
        .to be_a LlmClients::ServerError
      expect(anthropic.send(:translate, Anthropic::Errors::APIConnectionError.allocate))
        .to be_a LlmClients::ConnectionFailed
      expect(anthropic.send(:translate, Anthropic::Errors::AuthenticationError.allocate))
        .to be_a LlmClients::MissingCredentials
      expect(anthropic.send(:translate, Anthropic::Errors::BadRequestError.allocate))
        .to be_a LlmClients::RequestRejected
    end
  end
end
