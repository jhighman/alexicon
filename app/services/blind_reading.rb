# A person typing claims without seeing what the machine said.
#
# Every figure in the baseline is the system agreeing or disagreeing with
# itself. Nine measurements of consistency and none of correctness — a model can
# be perfectly consistent and consistently wrong, and nothing measured so far
# can tell those apart. The only thing that can is a person typing the same
# claims independently.
#
# "Independently" is a property of the procedure, not of good intentions. If the
# machine's category is on the screen, what gets measured is anchoring. So the
# blindness lives here rather than in the template: asking this object what the
# machine said, about a claim the reader has not yet answered, raises. A view
# cannot leak what it cannot obtain.
#
# This is the Sentinel Principle turned on the evaluation itself — the reading
# that judges the classifier must not be downstream of the classifier.
class BlindReading
  # Raised when the machine's reading is requested before the person has
  # committed theirs. Deliberately not rescued anywhere: it means a caller tried
  # to show the answer before the question was answered, which is a bug in the
  # measurement rather than a condition to recover from.
  Blinded = Class.new(StandardError)

  # The same window the batched classifier was given. Context changes the answer
  # — 65% alone against 87.9% in context — so a person reading with more or less
  # of it is not answering the same question the machine answered.
  CONTEXT_CLAIMS = 4

  # `unsure` is not a probability. It records that the person could type the
  # claim but would not stake much on it, which is the difference between a
  # disagreement that indicts the classifier and one that indicts the category
  # boundary.
  SURE = 1.0
  UNSURE = 0.5

  Pair = Data.define(:claim, :human, :machine, :unsure, :machine_agreement) do
    def both_typed? = human.present? && machine.present?
    def agreed? = both_typed? && human == machine
    def disagreed? = both_typed? && human != machine
    def human_only? = human.present? && machine.blank?
    def machine_only? = human.blank? && machine.present?
    def both_abstained? = human.blank? && machine.blank?
  end

  Comparison = Data.define(:pairs) do
    def both_typed = pairs.select(&:both_typed?)
    def agreed = pairs.count(&:agreed?)
    def disagreed = pairs.select(&:disagreed?)
    def human_only = pairs.count(&:human_only?)
    def machine_only = pairs.count(&:machine_only?)
    def both_abstained = pairs.count(&:both_abstained?)

    # Over claims BOTH typed. A claim one side abstained on is not a
    # disagreement about its category; counting it as one would conflate
    # coverage with correctness, which is the mistake section 9 warns about.
    def rate = both_typed.empty? ? nil : (agreed.to_f / both_typed.size).round(3)

    # Where the person was sure and the machine still disagreed. The subset that
    # actually bears on whether the classifier is right.
    def confident_disagreements = disagreed.reject(&:unsure)

    def moves
      disagreed.map { "#{it.machine.key}->#{it.human.key}" }.tally.sort_by { -it.last }.to_h
    end
  end

  def initialize(document, reader:)
    @document = document
    @reader = reader
  end

  attr_reader :document, :reader

  # Document order, and every substantive claim — not only the ones the machine
  # typed. Queueing only those would tell the reader, before they answered, that
  # the machine had an opinion; and 30 claims in the last run ended with no
  # machine reading at all, which is exactly where a person's judgement is worth
  # most.
  def queue = document.claims.substantive.order(:position)

  def total = queue.count

  def answered_count = answers.size

  def complete? = answered_count >= total

  def next_claim = queue.reject { answers.key?(it.id) }.first

  # Preceding claims as text only. No categories, no flags, no marginal
  # judgements: the context the classifier had, and nothing the classifier
  # concluded.
  def context_for(claim)
    document.claims.substantive
            .where(position: ...claim.position)
            .reorder(position: :desc).limit(CONTEXT_CLAIMS)
            .reverse
  end

  def answered?(claim) = answers.key?(claim.id)

  # The guard. A caller that has not established the reader answered cannot see
  # what the machine said.
  def machine_reading_for(claim)
    unless answered?(claim)
      raise Blinded, "claim #{claim.id} has not been typed by #{reader} yet — " \
                     "showing the machine's reading first would measure anchoring, " \
                     "not agreement"
    end

    claim.machine_agreement
  end

  def record!(claim, category:, rationale: nil, unsure: false)
    claim.classify!(category, asserter: reader, rationale: rationale.presence,
                    confidence: unsure ? UNSURE : SURE)
      .tap { reset }
  end

  # A person saying "I cannot tell" is a reading, and has to be distinguishable
  # from a claim nobody has reached yet — otherwise the queue never empties and
  # the abstention is invisible to the comparison.
  def abstain!(claim, rationale: nil)
    claim.abstain!(asserter: reader, rationale: rationale.presence).tap { reset }
  end

  # Only over what this reader has answered. An unanswered claim contributes
  # nothing rather than counting as an abstention.
  def comparison
    answered = queue.select { answers.key?(it.id) }
    Comparison.new(pairs: answered.map { pair_for(it) })
  end

  private

  def pair_for(claim)
    mine = answers[claim.id]
    machine = claim.machine_agreement

    Pair.new(claim: claim, human: mine.object, machine: machine.category,
             unsure: mine.claim["confidence"] == UNSURE, machine_agreement: machine)
  end

  # The reader's own standing readings, one per claim, latest wins.
  def answers
    @answers ||= Assertion.acting("classify").standing
                          .where(asserter: reader, subject_type: "Claim",
                                 subject_id: queue.select(:id))
                          .includes(:object).chronological
                          .index_by(&:subject_id)
  end

  def reset = @answers = nil
end
