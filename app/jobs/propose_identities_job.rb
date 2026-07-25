class ProposeIdentitiesJob < ApplicationJob
  queue_as :default

  discard_on IdentityProposer::MissingCredentials
  discard_on IdentityProposer::NoGovernedModel

  retry_on LlmClients::Retryable, wait: :polynomially_longer, attempts: 5

  def perform(document)
    IdentityProposer.call(document)
  end
end
