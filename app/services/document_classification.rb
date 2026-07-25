# Classifies every unclassified claim in a document.
#
# Identity precedes reasoning, so this refuses to run while the document is
# locked -- the same guard the Classification assertion enforces individually,
# checked once up front so the failure is legible instead of arriving 40 claims
# in.
#
# The run itself is recorded as an assertion by the classifier: "I looked at
# this document and classified n, abstained on m." That keeps run state derived
# rather than stored, and makes the attempt attributable like everything else.
# Abstentions are counted, never recorded as classifications -- an abstention is
# the absence of a judgement, and writing one down would invent the judgement
# it declined to make.
class DocumentClassification
  Result = Data.define(:document, :classified, :abstained, :skipped) do
    def attempted = classified + abstained
  end

  def self.call(document, **) = new(document, **).call

  # on_progress is called after each claim with the claim and its outcome
  # (:classified, :abstained or :skipped). It is for reporting only -- raising
  # from it must not be able to derail a run, so it is guarded at the call site.
  def initialize(document, classifier: ClaimClassifier, on_progress: nil)
    @document = document
    @classifier = classifier
    @on_progress = on_progress
  end

  def call
    document.require_executable!

    classified = abstained = skipped = 0

    document.claims.each_with_index do |claim, index|
      # Never reclassify. A standing classification is answered by a person or
      # superseded deliberately, not overwritten by a second pass.
      if claim.category
        skipped += 1
        report(claim, :skipped, index)
        next
      end

      outcome = classifier.new(claim).classify! ? :classified : :abstained
      outcome == :classified ? classified += 1 : abstained += 1
      report(claim, outcome, index)
    end

    record_run(classified, abstained, skipped)
    Result.new(document: document, classified: classified, abstained: abstained, skipped: skipped)
  end

  private

  attr_reader :document, :classifier, :on_progress

  # Telling someone what is happening must never change what happens. A broken
  # subscriber, a dropped socket, a view that raises -- none of that is grounds
  # for abandoning classifications already made.
  def report(claim, outcome, index)
    return if on_progress.nil?

    on_progress.call(claim: claim, outcome: outcome, index: index)
  rescue StandardError => e
    Rails.logger.warn("classification progress report failed: #{e.class}: #{e.message}")
  end

  def record_run(classified, abstained, skipped)
    Assertion.create!(
      asserter: Referent.find_by!(key: "claim-classifier"),
      subject: document,
      act: "assert",
      claim: { "run" => "classification", "classified" => classified,
               "abstained" => abstained, "skipped" => skipped }
    )
  end
end
