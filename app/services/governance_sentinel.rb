# Governs the promotion of a claim into the next kind of claim.
#
#   "Has this interpretation earned the right to guide action?"
#
# It does not judge whether a claim is true. It judges whether the move BETWEEN
# two claims was warranted -- whether the confidence of the second exceeds the
# evidence class the first could underwrite.
#
# Three properties distinguish this from validation:
#
#   * It never returns true or false. An unearned promotion is reported as a
#     category change outrunning its justification, and the author keeps the
#     right to reject that reading.
#   * It refuses to judge what it cannot judge. An unclassified endpoint yields
#     no verdict at all, rather than a confident "undetermined" -- a system
#     that judged every pair would be manufacturing the confidence it exists
#     to police.
#   * It will not govern its own work. Chapter 6 requires the evaluator to be
#     independent of the transformation it governs; a sentinel that classified
#     a claim may not also rule that the classification earned its promotion.
#
# Severity is `concern`, not `stop`. Identity failures halt execution because
# the conditions for proceeding were never met. A promotion is different: the
# author may well be entitled to it, and the Sentinel's job is to make the
# step visible, not to prevent it. Agency is preserved.
class GovernanceSentinel
  SEVERITY = "concern".freeze

  Result = Data.define(:transition, :verdict, :reason, :flag) do
    def judged? = !verdict.nil?
    def unearned? = verdict == "unearned"
  end

  class NotIndependent < StandardError; end

  def self.review!(transition, framework: Framework.current_or_none)
    new(transition, framework: framework).review!
  end

  # Reviews every transition in a document, skipping none silently.
  def self.review_document!(document, framework: Framework.current_or_none)
    document.require_executable!
    document.transitions.map { review!(it, framework: framework) }
  end

  # The framework is a parameter because the same step, judged under different
  # premises, is a different question — and the answers have to be able to
  # coexist rather than overwrite each other. `alexicon-2.0` charges 2 for
  # `ontological → normative` with a rationale naming Hume; `lewisian-1.0`
  # charges 0, holding that a claim about what ought to be is a claim about what
  # is. Both may now rule on the same transition, and both rulings stand.
  def initialize(transition, framework: Framework.current_or_none)
    @transition = transition
    @framework = framework
  end

  def review!
    # Identity precedes reasoning. A document whose subjects are ungrounded
    # cannot have its promotions judged.
    transition.document&.require_executable!
    refuse_self_review!

    return unjudged("either claim is unclassified") unless both_classified?
    return record("earned", "no category change; nothing was promoted") unless category_change?
    # Before any verdict about the move: does the framework say what it costs?
    return unjudged(unweighted_reason) unless weighted?
    return record("earned", lateral_reason) unless promotion?
    return record("earned", "the promotion is supported by evidence presented with it") if evidence_presented?

    flag_unearned
  end

  private

  attr_reader :transition, :framework

  # A claim is classified under whichever framework was current when it was
  # read, so judging it under another means finding that framework's word for
  # the same category. Matched by key, which is the stable identifier across
  # versions — `ontological` means the same thing to Hume and to Lewis, and what
  # differs is only what the move between kinds costs.
  #
  # nil when the framework has no such category. That is not a licence to fall
  # back to the claim's own framework: a framework that does not speak this
  # vocabulary has not said what the move costs, and `weighted?` will decline.
  def counterpart(category)
    return nil if category.blank?
    return category if category.framework_id == framework&.id

    ClaimCategory.find_by(framework: framework, key: category.key)
  end

  def from_classification = transition.from_claim&.classification
  def to_classification   = transition.to_claim&.classification

  def both_classified? = from_classification.present? && to_classification.present?

  def from_category = from_classification.object
  def to_category   = to_classification.object

  def category_change? = from_category != to_category

  # A promotion is a move that costs something -- not merely a different kind.
  #
  # Reads CategoryPromotion rather than justification_rank so that what a move
  # costs has ONE source. The two encodings agreed on every ordered pair when
  # this changed, so no verdict moved; what changes is that editing a weight now
  # reaches the verdict as well as the audit, instead of the two drifting.
  #
  # Still a binary question. The magnitude is available and deliberately unused:
  # requiring more evidence for a heavier promotion would be a policy change
  # nobody has asked for, and it would move every verdict the baseline measured.
  def promotion? = promotion_weight.positive?

  # nil means the framework has not said what this move costs, which is not the
  # same as saying it costs nothing. Treating the absence as zero would judge
  # every step of an unweighted framework "earned" — silently permissive, in the
  # one place this system is supposed to refuse rather than guess.
  def promotion_weight
    @promotion_weight ||= CategoryPromotion.weight_for(
      from: counterpart(from_category), to: counterpart(to_category), framework: framework
    )
  end

  def weighted? = !promotion_weight.nil?

  # Evidence attached to the classification that asserted the higher category.
  # "Additional justification" has to be something the record can show.
  def evidence_presented? = to_classification.evidence.any?

  def sentinel = @sentinel ||= Referent.sentinel_for("governance")

  # The mechanism responsible for producing an assertion may not be solely
  # responsible for determining that it satisfies the conditions for
  # advancement.
  def refuse_self_review!
    authored = [ from_classification, to_classification ].compact.map(&:asserter)
    return unless authored.include?(sentinel)

    raise NotIndependent,
          "the Governance Sentinel classified one of these claims and cannot also " \
          "rule that the classification earned its promotion"
  end

  def unweighted_reason
    "the framework does not say what #{from_category.name} → #{to_category.name} costs, " \
      "so whether it was earned cannot be ruled on"
  end

  def lateral_reason
    "#{from_category.name} → #{to_category.name} changes the kind of claim without " \
      "increasing the justification burden"
  end

  def unjudged(reason)
    Result.new(transition: transition, verdict: nil, reason: reason, flag: nil)
  end

  def record(verdict, reason)
    transition.record_verdict!(verdict, asserter: sentinel, rationale: reason, framework: framework)
    Result.new(transition: transition, verdict: verdict, reason: reason, flag: nil)
  end

  def flag_unearned
    reason = "#{from_category.name} → #{to_category.name}: the confidence of the statement " \
             "now exceeds the evidence class presented"
    transition.record_verdict!("unearned", asserter: sentinel, rationale: reason, framework: framework)
    flag = Assertion.create!(
      asserter: sentinel,
      subject: transition,
      act: "flag",
      framework: framework,
      claim: { "severity" => SEVERITY, "message" => message(reason) }
    )
    Result.new(transition: transition, verdict: "unearned", reason: reason, flag: flag)
  end

  # States that the claim has left the domain its evidence could underwrite.
  # It does not say the author is wrong, and it does not resolve the question.
  def message(reason)
    "#{reason}. This is not a judgement that the claim is false. It records that " \
      "the claim changed category without a corresponding increase in justification."
  end
end
