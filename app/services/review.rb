# What is waiting for a person, in the order their attention is worth most.
#
# The counterpart to `BlindReading`, and deliberately not the same surface.
# Blind typing is a MEASUREMENT: a reader who could not have seen the answer,
# so their agreement means something. This is CORRECTION: the system's
# conclusion is shown, and a person disposes of it.
#
# The two must never merge, and the boundary is enforced here rather than
# remembered: **this queue never serves a claim classification.** If it did, a
# reviewer would see the machine's category for the same claims the blind
# surface needs them naive for, and the only measurement in this system that is
# not the system checking itself would stop being worth taking. Claims are typed
# blind or not at all. Judgements are reviewed here.
#
# It follows that nothing recorded through this surface can be used as a
# correctness baseline. An informed reader agreeing with the system is not
# evidence the system was right.
#
# The order is by how little the system knows:
#
#   1. VALUE READINGS, first because they are the weakest thing here. Three
#      controls say the layer cannot distinguish a real step from a random pair,
#      so a person's disposal is the only filter that works — and one that
#      survives review is worth more than one that does not.
#   2. UNEARNED STEPS, where a verdict stands until somebody signs for it either
#      way. Accepting one is not overruling the Sentinel: the flag stays, the
#      verdict is undisturbed, and a named person takes responsibility for
#      letting it stand. That is the shape costly obedience has here.
class Review
  Item = Data.define(:kind, :assertion, :subject, :question, :detail, :context, :caveat) do
    def id = assertion.id
  end

  # Reviewing is a judgement about a judgement, so both acts are the ones the
  # record already has.
  VERDICTS = { "accept" => "accept", "reject" => "reject" }.freeze

  class UnknownVerdict < StandardError; end
  class NotReviewable < StandardError; end

  def initialize(document, reviewer:)
    @document = document
    @reviewer = reviewer
  end

  def queue = value_readings + unearned_steps

  def next_item = queue.first

  def total = queue.size

  def reviewed_count
    (value_reading_assertions + step_verdicts).count { it.disposition != "open" }
  end

  # Recorded beside what it disposes of, never over it. The reviewed assertion
  # is untouched and stays standing; what changes is that somebody has now said
  # something about it.
  def dispose!(assertion, verdict:, rationale: nil)
    act = VERDICTS.fetch(verdict.to_s) { raise UnknownVerdict, "accept or reject, not #{verdict}" }
    raise NotReviewable, "not in this queue" unless reviewable?(assertion)

    payload = {}
    payload["rationale"] = rationale if rationale.present?

    Assertion.create!(asserter: reviewer, subject: assertion, act: act, claim: payload)
  end

  private

  attr_reader :document, :reviewer

  def transitions = @transitions ||= document.transitions.to_a

  def value_reading_assertions
    @value_reading_assertions ||= transitions.flat_map do |t|
      t.assertions.standing.select { it.claim["inference"] == "step value" }
    end
  end

  def step_verdicts
    @step_verdicts ||= transitions.select(&:unearned?).filter_map { it.ruling }
  end

  def reviewable?(assertion)
    (value_reading_assertions + step_verdicts).any? { it.id == assertion.id }
  end

  def value_readings
    value_reading_assertions.select { it.disposition == "open" }.map do |a|
      step = a.subject
      Item.new(
        kind: "value reading", assertion: a, subject: step,
        question: "Does this step put #{a.claim['protects']} before #{a.claim['against'] || a.claim['subordinates']}?",
        detail: a.claim["rationale"],
        context: [ step.source.text, step.target.text ],
        caveat: "This layer cannot distinguish a real step from an unrelated pair of " \
                "claims — three attempts to make it have failed. Its confidence means " \
                "nothing. Reject freely; that is what this queue is for."
      )
    end
  end

  def unearned_steps
    step_verdicts.select { it.disposition == "open" }.map do |a|
      step = a.subject
      Item.new(
        kind: "unearned step", assertion: a, subject: step,
        question: "The second claim asserts more than the first supports. Let it stand?",
        detail: "#{step.source.category&.key} → #{step.target.category&.key}",
        context: [ step.source.text, step.target.text ],
        caveat: "Accepting does not overrule the Sentinel. The verdict stays in the " \
                "record and so does your name against it — you are saying the step " \
                "may stand anyway, not that it was earned."
      )
    end
  end
end
