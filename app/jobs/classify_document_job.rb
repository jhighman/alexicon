class ClassifyDocumentJob < ApplicationJob
  queue_as :default

  # Retrying will not conjure an API key, and retrying a locked document will
  # not unlock it -- only a person can. Both are discarded rather than retried.
  # The page is told before the exception leaves #perform, so a discarded run
  # says why it stopped instead of animating forever.
  discard_on ClaimClassifier::MissingCredentials
  discard_on ClaimClassifier::NoGovernedModel
  discard_on Document::ExecutionLocked

  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on Anthropic::Errors::InternalServerError, wait: :polynomially_longer, attempts: 3

  def perform(document)
    broadcast(document, status: "running")
    DocumentClassification.call(document, on_progress: progress_reporter(document))

    # The page re-renders from the record rather than being told what to show,
    # so what a reviewer ends up looking at is the classifications themselves.
    Turbo::StreamsChannel.broadcast_refresh_to(document, :classification)
  rescue StandardError => e
    broadcast(document, status: "failed", error: failure_message(e))
    raise
  end

  private

  # Rendering the report costs a couple of queries, so on a document with
  # thousands of claims an update per claim would spend real time telling
  # someone about work it could have been doing. A few frames a second is as
  # much as anyone can read.
  MIN_REPORT_INTERVAL = 0.4

  def progress_reporter(document)
    last = 0.0

    ->(claim:, outcome:, index:) do
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return if index.positive? && (now - last) < MIN_REPORT_INTERVAL

      last = now
      broadcast(document, status: "running", current: claim.text, outcome: outcome)
    end
  end

  def broadcast(document, status:, current: nil, outcome: nil, error: nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      document, :classification,
      target: "classification-progress",
      partial: "documents/classification_progress",
      locals: { document: document, status: status, current: current,
                outcome: outcome, error: error }
    )
  end

  # A reviewer needs to know what to do next, not which class was raised.
  def failure_message(error)
    case error
    when ClaimClassifier::MissingCredentials
      "No API key for the provider it routed to — set one on the Providers page."
    when ClaimClassifier::NoGovernedModel
      "No model is routed to the classifier: #{error.message}."
    when Document::ExecutionLocked
      "Identity is unresolved — answer the open STOPs first."
    else
      "#{error.class}: #{error.message}"
    end
  end
end
