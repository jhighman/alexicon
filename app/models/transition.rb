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
  # Not a verdict. A verdict is what one framework concluded; this is the state
  # of there being more than one conclusion and no ground for choosing between
  # them. It is deliberately outside VERDICTS so that nothing can record it as a
  # judgement — no sentinel may assert "contested", it can only be observed.
  CONTESTED = "contested".freeze

  before_validation :default_kind

  def from_claim = source
  def to_claim = target

  def document = source&.document

  # What ONE framework concluded, from the standing governance assertions.
  #
  # This read "newest wins" across every ruling regardless of origin, and that
  # was wrong in two different ways at once. A ruling made under a Humean
  # framework and a ruling made under a Lewisian one are answers to DIFFERENT
  # QUESTIONS, and taking the later of the two reports one premise's answer as
  # though it were the record's. And two rulings by the same sentinel under the
  # same premises are the same question answered twice — where a difference is
  # drift, and quietly keeping the second hides that the instrument moved.
  #
  # So: scoped to a framework, collapsed per asserter (a judge revising itself
  # is one position, the latest), and CONTESTED when the surviving positions
  # disagree. Nothing is discarded and nothing is silently resolved.
  def verdict(at: Time.current, framework: Framework.current_or_none)
    values = positions(at: at, framework: framework).values.map { it.claim["verdict"] }.uniq
    return "undetermined" if values.empty?
    return CONTESTED if values.size > 1

    VERDICTS.include?(values.first) ? values.first : "undetermined"
  end

  # True when two asserters reached different conclusions under the SAME
  # premises. Genuine disagreement, and the one thing this class must never
  # resolve on its own.
  def contested?(at: Time.current, framework: Framework.current_or_none)
    verdict(at: at, framework: framework) == CONTESTED
  end

  # True when ONE asserter changed its own answer under the same premises. Not
  # disagreement — drift, which is a fact about the instrument rather than about
  # the step, and is reported separately for that reason.
  def unstable?(at: Time.current, framework: Framework.current_or_none)
    rulings(at: at, framework: framework).group_by(&:asserter_id)
                                         .any? { |_, rs| rs.map { it.claim["verdict"] }.uniq.size > 1 }
  end

  # Every framework that has ruled here, and what each concluded. The point of
  # the whole exercise: two premises produce two standing answers rather than
  # one overwriting the other.
  def verdicts(at: Time.current)
    frameworks_ruling(at: at).index_with { verdict(at: at, framework: it) }
  end

  def frameworks_ruling(at: Time.current)
    Framework.where(id: all_rulings(at: at).filter_map(&:framework_id).uniq).to_a
  end

  def score(at: Time.current) = ruling(at: at)&.claim&.fetch("score", nil)&.to_f

  # The last assertion under this framework that actually RULED, rather than the
  # last assertion of any kind.
  #
  # This read `current_claim` — the latest assertion whatever it was — so
  # anything else recorded about a step silently erased its verdict. Nothing had
  # exercised it, because until then only the Sentinel ever wrote to a
  # transition. `StepValueJudge` writes what a flagged step protects, and its
  # first spec found a step judged unearned reporting itself undetermined a
  # moment later.
  #
  # Singular, so it cannot answer a contested step: use `positions` for who says
  # what and `verdict` for whether they agree. This exists for the things that
  # need one assertion to point at — a review queue item, a rationale to show.
  def ruling(at: Time.current, framework: Framework.current_or_none)
    rulings(at: at, framework: framework).last
  end

  # Every standing ruling under one framework, oldest first.
  def rulings(at: Time.current, framework: Framework.current_or_none)
    all_rulings(at: at).select { it.framework_id == framework&.id }
  end

  # One position per asserter: the latest thing each said. A judge that ruled
  # three times gets one vote, not three.
  def positions(at: Time.current, framework: Framework.current_or_none)
    rulings(at: at, framework: framework).group_by(&:asserter_id).transform_values(&:last)
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
  #
  # The framework is stamped rather than optional. A ruling that does not name
  # the premises it was made under cannot be told apart from one made under any
  # other, and an unattributable judgement is the thing this class exists to
  # prevent being recorded.
  def record_verdict!(verdict, asserter:, score: nil, rationale: nil, framework: Framework.current_or_none)
    raise ArgumentError, "unknown verdict #{verdict}" unless VERDICTS.include?(verdict.to_s)

    payload = { "verdict" => verdict.to_s }
    payload["score"] = score if score
    payload["rationale"] = rationale if rationale

    assertions.create!(asserter: asserter, act: "assert", claim: payload, framework: framework)
  end

  private

  # Deliberately not scoped to a framework: what `frameworks_ruling` reads to
  # find out which premises have answered here at all.
  def all_rulings(at: Time.current)
    established_assertions(at: at).select { it.claim.key?("verdict") }
  end

  def default_kind
    self.kind ||= KIND
  end
end
