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
  def initialize(document, classifier: ClaimClassifier, on_progress: nil, framework: nil)
    @document = document
    @classifier = classifier
    @on_progress = on_progress
    @framework = framework
  end

  # Deliberately does NOT require the document to be executable. Typing a
  # statement does not predicate anything of the names inside it, and demanding
  # every name resolve first meant a document citing an unfamiliar author could
  # not be read at all. Identity still gates governance, which does reason about
  # what the names refer to.
  def call
    classified = abstained = skipped = 0

    ordered = document.claims.to_a
    index = -1

    # Never reclassify. A standing classification is answered by a person or
    # superseded deliberately, not overwritten by a second pass.
    already, pending = ordered.partition(&:category)
    already.each { skipped += 1 }

    ordered.each_with_index do |claim, position|
      next unless claim.category

      report(claim, :skipped, position)
    end

    pending.each_slice(ClaimClassifier::BATCH_SIZE) do |batch|
      results = classifier.new(batch, framework: framework,
                                      context: preceding(ordered, batch.first)).classify!

      batch.each do |claim|
        outcome = results[claim] ? :classified : :abstained
        outcome == :classified ? classified += 1 : abstained += 1
        report(claim, outcome, index += 1)
      end
    end

    record_run(classified, abstained, skipped)
    Result.new(document: document, classified: classified, abstained: abstained, skipped: skipped)
  end

  private

  attr_reader :document, :classifier, :on_progress, :framework

  # The claims immediately before a batch, so the model can tell what a pronoun
  # or a "therefore" is pointing back at.
  def preceding(ordered, first)
    start = ordered.index(first).to_i
    ordered[[ start - ClaimClassifier::CONTEXT_CLAIMS, 0 ].max...start].to_a
  end

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
