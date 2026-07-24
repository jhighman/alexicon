# A governed edge between two claims: the move from one statement to the next.
#
# The transition -- not the claim -- is the unit of risk. A claim may be
# perfectly sound; the danger is the unannounced promotion between claims.
#
# It is a Relationship because it is the same construct: an independently
# governable connection with a lifecycle, evidence, and a standing derived
# from accountable assertions rather than stored as a column.
#
# `verdict` is therefore not a field. A sentinel ASSERTS that a transition was
# earned or unearned, and that assertion is attributable, evidenced, and open
# to challenge like any other. "Undetermined" is the absence of such an
# assertion, so a system that has not yet judged says so rather than
# manufacturing the confidence it exists to police.
class Transition < Relationship
  KIND = "epistemic_transition".freeze
  VERDICTS = %w[earned unearned undetermined].freeze

  before_validation :default_kind

  def from_claim = source
  def to_claim = target

  def document = source&.document

  # Derived from the standing governance assertions, newest wins.
  def verdict(at: Time.current)
    claim = current_claim(at: at)
    value = claim && claim["verdict"]
    VERDICTS.include?(value) ? value : "undetermined"
  end

  def score(at: Time.current)
    value = current_claim(at: at)&.fetch("score", nil)
    value&.to_f
  end

  def unearned?(at: Time.current) = verdict(at: at) == "unearned"

  # True when the endpoints carry different categories -- a category change,
  # which is what the Sentinel watches for. It says nothing about whether the
  # change was earned.
  def category_change?
    from = from_claim&.category
    to   = to_claim&.category
    from.present? && to.present? && from != to
  end

  # Records a judgement as an accountable assertion rather than a column write.
  def record_verdict!(verdict, asserter:, score: nil, rationale: nil)
    raise ArgumentError, "unknown verdict #{verdict}" unless VERDICTS.include?(verdict.to_s)

    payload = { "verdict" => verdict.to_s }
    payload["score"] = score if score
    payload["rationale"] = rationale if rationale

    assertions.create!(asserter: asserter, act: "assert", claim: payload)
  end

  private

  def default_kind
    self.kind ||= KIND
  end
end
