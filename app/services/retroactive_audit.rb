# When a step is judged unearned, look back at what it was standing on.
#
# Alexandra Krížová's *gravitational inversion*: analysis normally flows
# forward — claim, category, step, verdict — and when an anomaly appears the
# pull reverses and the claims underneath are audited.
#
# The reason it is worth having is that a verdict on a single step is local. It
# says this move was not earned; it does not say where the argument actually
# left its ground. Four unearned steps in a row are not four independent
# failures, they are one failure with three consequences, and the claim to look
# at is the first one.
#
# Three things it must not do, all of which follow from the Sentinel Principle:
#
#   * It does not re-judge a step. It reads standing verdicts and points at the
#     claims implicated by their PATTERN. The Governance Sentinel ruled; this
#     asks a different question about the ruling.
#   * It does not re-classify. A claim under suspicion is flagged for a person,
#     not quietly retyped — that would be the auditor performing the
#     transformation it exists to question.
#   * It calls no model. Every signal below is computable from the categories
#     and the verdicts already recorded, so a finding can be checked by hand.
class RetroactiveAudit
  AUDITOR = "retroactive-audit".freeze

  # A jump of more than one justification rank in a single step. objective and
  # observation share rank 1, interpretive is 2, ontological is 3 — so
  # observation straight to ontological skips a rank, which is the manuscript's
  # own example: "I saw a wall collapsing" to "there is a God".
  MAX_RANK_STEP = 1

  # Two consecutive unearned steps is already a run: the argument did not
  # recover between them.
  MIN_RUN = 2

  Finding = Data.define(:kind, :claim, :message, :steps) do
    def to_s = "#{kind} on claim #{claim.position}"
  end

  def self.review!(document) = new(document).review!
  def self.findings_for(document) = new(document).findings

  def initialize(document)
    @document = document
  end

  # Raises a concern per finding, and returns the flags. A concern, never a
  # STOP: this is a finding about an argument, not a refusal to proceed.
  def review!
    findings.filter_map do |finding|
      next if already_raised?(finding)

      Assertion.create!(
        asserter: auditor, subject: finding.claim, act: "flag",
        claim: { "severity" => "concern", "message" => finding.message,
                 "audit" => finding.kind.to_s,
                 "steps" => finding.steps.map(&:id) }
      )
    end
  end

  def findings
    return [] if unearned.empty?

    (rank_skips + runs + load_bearing).uniq { [ it.kind, it.claim.id ] }
  end

  private

  attr_reader :document

  def auditor = @auditor ||= Referent.find_by!(key: AUDITOR)

  def steps
    @steps ||= document.transitions.includes(:source, :target)
                       .select { it.from_claim && it.to_claim }
                       .sort_by { it.from_claim.position }
  end

  def unearned = @unearned ||= steps.select(&:unearned?)

  # A step that promotes a claim more than one rank at once. The claim it lands
  # on is asserting more than any single move can carry, so either an
  # intermediate claim is missing or one of the endpoints is mistyped.
  def rank_skips
    unearned.filter_map do |step|
      from = step.from_claim.category&.justification_rank
      to = step.to_claim.category&.justification_rank
      next if from.nil? || to.nil? || (to - from) <= MAX_RANK_STEP

      Finding.new(
        kind: :rank_skip, claim: step.to_claim, steps: [ step ],
        message: "This claim is #{to - from} justification ranks above the one before it, " \
                 "in a single step that was judged unearned. Either a claim is missing " \
                 "between them, or one of the two is typed wrongly."
      )
    end
  end

  # A run of consecutive unearned steps is one failure with consequences. The
  # claim to look at is where the run STARTS -- the last place the argument was
  # still on ground.
  def runs
    consecutive.filter_map do |run|
      next if run.size < MIN_RUN

      Finding.new(
        kind: :run, claim: run.first.from_claim, steps: run,
        message: "#{run.size} consecutive steps from here were judged unearned. " \
                 "This is the last claim before the argument left its ground, so it is " \
                 "the one to examine rather than each step after it."
      )
    end
  end

  # A claim that was reached by an unearned step and is then used as the ground
  # for another. It is carrying weight it did not earn.
  def load_bearing
    reached = unearned.map(&:to_claim).to_set
    unearned.filter_map do |step|
      next unless reached.include?(step.from_claim)
      next if in_a_run?(step)

      Finding.new(
        kind: :load_bearing, claim: step.from_claim, steps: [ step ],
        message: "This claim was itself reached by a step judged unearned, and is now " \
                 "being used as the ground for another. It is carrying weight it did " \
                 "not earn."
      )
    end
  end

  # Runs of unearned steps that are actually adjacent in the argument.
  def consecutive
    steps.chunk_while { |a, b| a.unearned? && b.unearned? && a.to_claim == b.from_claim }
         .select { it.size >= MIN_RUN && it.all?(&:unearned?) }
  end

  # A load-bearing claim inside a run is already reported by the run finding,
  # which names a better place to look.
  def in_a_run?(step) = consecutive.any? { it.include?(step) }

  # One flag per claim per kind, however often the audit runs.
  def already_raised?(finding)
    finding.claim.assertions.flags.standing.any? { it.claim["audit"] == finding.kind.to_s }
  end
end
