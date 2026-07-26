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
  # `readings` is how many machine opinions each claim should end up with. One
  # reading is a sample: re-running a whole document changed half the steps it
  # flagged. Asking for more does not overwrite anything -- each reading is its
  # own assertion, and the claim's category becomes what a majority of them say.
  #
  # It is also incremental. A document already carrying one reading, run again
  # at 3, buys two more rather than starting over.
  def initialize(document, classifier: ClaimClassifier, on_progress: nil, framework: nil,
                 readings: 1)
    @document = document
    @classifier = classifier
    @on_progress = on_progress
    @framework = framework
    @readings = readings
  end

  # Deliberately does NOT require the document to be executable. Typing a
  # statement does not predicate anything of the names inside it, and demanding
  # every name resolve first meant a document citing an unfamiliar author could
  # not be read at all. Identity still gates governance, which does reason about
  # what the names refer to.
  def call
    @declined = Hash.new(0)
    @touched = Set.new

    # Headings are part of the document but are not claims about anything, so
    # nothing asks them what kind of claim they are.
    ordered = document.claims.reject(&:structural?)
    index = -1

    # Never REPLACE a reading -- but a second opinion is not a replacement. A
    # claim is skipped when a person has settled it, or when it already carries
    # as many machine readings as were asked for.
    skipped = ordered.count { settled?(it) }
    ordered.each_with_index { |claim, position| report(claim, :skipped, position) if settled?(claim) }

    # One pass adds one reading to each claim that still wants one, so reaching
    # `readings` takes as many passes. A pass that adds nothing stops the loop
    # rather than spinning -- an unclassifiable claim must not cost a call per
    # pass forever.
    loop do
      pending = ordered.reject { settled?(it) }
      break if pending.empty?

      take_one_reading(pending, ordered) do |claim, outcome|
        # An abstention is an answer, not a failure to give one. It counts
        # against the readings asked for, or a claim the classifier keeps
        # declining would cost a call on every pass.
        @declined[claim.id] += 1 if outcome == :abstained
        @touched << claim.id
        report(claim, outcome, index += 1)
      end
    end

    # What THIS RUN did, over claims rather than readings: a claim read three
    # times is still one claim, and one that was already settled is not
    # something this run classified.
    touched = ordered.select { @touched.include?(it.id) }
    classified = touched.count { it.category }
    abstained = touched.count { it.category.nil? }

    record_run(classified, abstained, skipped)
    Result.new(document: document, classified: classified, abstained: abstained, skipped: skipped)
  end

  private

  attr_reader :document, :classifier, :on_progress, :framework, :readings

  # One reading for each claim that still wants one.
  def take_one_reading(pending, ordered)
    pending.each_slice(ClaimClassifier::BATCH_SIZE) do |batch|
      results = classifier.new(batch, framework: framework,
                                      context: preceding(ordered, batch.first)).classify!

      batch.each { |claim| yield claim, results[claim] ? :classified : :abstained }
    end
  end

  # A person's judgement settles the question outright; machine readings settle
  # it once the claim has been asked as many times as was requested -- counting
  # a decline as an asking.
  def settled?(claim)
    return true if claim.classifications.any?(&:human?)

    claim.agreement.readings + @declined[claim.id] >= readings
  end

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
