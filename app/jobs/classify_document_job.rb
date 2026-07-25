class ClassifyDocumentJob < ApplicationJob
  queue_as :default

  # Retrying will not conjure an API key, and retrying a locked document will
  # not unlock it -- only a person can. Both are discarded rather than retried.
  # The page is told before the exception leaves #perform, so a discarded run
  # says why it stopped instead of animating forever.
  discard_on ClaimClassifier::MissingCredentials
  discard_on ClaimClassifier::NoGovernedModel
  discard_on Document::ExecutionLocked

  # Retryable in the adapters' terms, not a vendor's. The previous rules named
  # Anthropic's SDK, so a Gemini rate limit -- a different class entirely --
  # fell straight through and stopped the run.
  #
  # Re-running is cheap: a claim with a standing classification is skipped, so
  # a retry resumes rather than repeating the calls already paid for.
  # The block replaces the re-raise, so without raising again the queue would
  # record a job that gave up as one that succeeded. Tell the reviewer, then
  # let it fail properly.
  retry_on LlmClients::Retryable, wait: :polynomially_longer, attempts: 5 do |job, error|
    job.report_exhausted(error)
    raise error
  end

  def perform(document)
    broadcast(document, status: "running")
    DocumentClassification.call(document, on_progress: progress_reporter(document))

    # The page re-renders from the record rather than being told what to show,
    # so what a reviewer ends up looking at is the classifications themselves.
    Turbo::StreamsChannel.broadcast_refresh_to(document, :classification)
  rescue LlmClients::Retryable => e
    # Not a failure yet. Saying "stopped" here and then quietly resuming would
    # be worse than saying nothing.
    broadcast(document, status: "retrying", error: retry_message(e))
    raise
  rescue StandardError => e
    broadcast(document, status: "failed", error: failure_message(e))
    raise
  end

  # Called by retry_on once the attempts are used up, which is the point at
  # which "waiting" becomes "stopped".
  def report_exhausted(error)
    document = arguments.first
    broadcast(document, status: "failed",
                        error: "Gave up after #{executions} attempts. #{failure_message(error)}")
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

  def retry_message(error)
    wait = error.retry_after ? " The provider asked for #{error.retry_after}s." : ""

    case error
    when LlmClients::RateLimited then "Rate limited — waiting, then resuming.#{wait}"
    when LlmClients::ServerError then "The provider returned an error — waiting, then resuming."
    else "Could not reach the provider — waiting, then resuming."
    end
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
    when LlmClients::RateLimited
      "The provider kept rate limiting the request."
    when LlmClients::RequestRejected
      "The provider rejected the request: #{error.message}"
    else
      "#{error.class}: #{error.message}"
    end
  end
end
