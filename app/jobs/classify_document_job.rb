class ClassifyDocumentJob < ApplicationJob
  queue_as :default

  # Retrying will not conjure an API key, and retrying a locked document will
  # not unlock it -- only a person can. Both are discarded rather than retried.
  discard_on ClaimClassifier::MissingCredentials
  discard_on Document::ExecutionLocked

  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on Anthropic::Errors::InternalServerError, wait: :polynomially_longer, attempts: 3

  def perform(document)
    DocumentClassification.call(document)
  end
end
