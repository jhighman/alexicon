require "rails_helper"

# A credential has two possible homes and they behave differently, so which one
# is in effect must never be a guess.
RSpec.describe "provider credentials" do
  before { seed_quietly }

  let(:provider) { LlmProvider.find_by!(key: "anthropic") }
  let(:admin) { Referent.create!(key: "ana", name: "Ana", primitive: "person") }

  it "is encrypted at rest, so a dump of the table does not hand over the key" do
    provider.set_api_key!("sk-ant-secret-value", by: admin)

    raw = LlmProvider.connection.select_value(
      "SELECT api_key FROM llm_providers WHERE id = #{provider.id}"
    )

    expect(raw).to be_present
    expect(raw).not_to include "sk-ant-secret-value"
    expect(provider.reload.api_key).to eq "sk-ant-secret-value"
  end

  it "prefers a stored key over the environment, because storing one is a deliberate act" do
    with_env(ANTHROPIC_API_KEY: "from-env") do
      expect(provider.credential_source).to eq "environment"
      expect(provider.api_key_in_effect).to eq "from-env"

      provider.set_api_key!("from-gui", by: admin)

      expect(provider.credential_source).to eq "stored"
      expect(provider.api_key_in_effect).to eq "from-gui"
    end
  end

  it "falls back to the environment when the stored key is cleared" do
    provider.set_api_key!("from-gui", by: admin)

    with_env(ANTHROPIC_API_KEY: "from-env") do
      provider.clear_api_key!

      expect(provider.credential_source).to eq "environment"
      expect(provider.api_key_in_effect).to eq "from-env"
    end
  end

  it "records who set it and when, but never the value itself" do
    provider.set_api_key!("sk-ant-secret-value", by: admin)

    expect(provider.api_key_set_by).to eq admin
    expect(provider.api_key_set_at).to be_present
    expect(provider.api_key_hint).to eq "…alue"
  end

  it "reports no credential when neither home has one" do
    with_env(ANTHROPIC_API_KEY: nil) do
      expect(provider.credential_source).to be_nil
      expect(provider).not_to be_credentialed
    end
  end

  it "names both places to look when a call finds no key" do
    with_env(ANTHROPIC_API_KEY: nil) do
      model = LlmModel.find_by!(model_identifier: "claude-opus-5")

      expect { model.client.send(:api_key) }
        .to raise_error(LlmClients::MissingCredentials, /llm_providers.*ANTHROPIC_API_KEY/m)
    end
  end
end
