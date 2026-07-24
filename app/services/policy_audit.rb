# Checks a scorer against a cross-cutting policy, and records the result.
#
# The policy is not enforced by hoping a scorer behaves. It is enforced by a
# contract any scorer must pass, and by an assertion recording that the check
# was run, by whom, and what it found — so "we checked" is itself an
# accountable claim rather than a comment in a file.
#
# A failing audit is recorded too. An architecture that only writes down its
# passes is keeping a marketing record, not an audit trail.
class PolicyAudit
  POLICY_KEY = "anti-discrimination".freeze

  # A record shaped like a real one: several evidenced relationships of
  # different kinds, spaced continuously. The variant under test adds a gap.
  SAMPLE_KINDS = %w[employment education licence].freeze

  Result = Data.define(:policy, :criterion, :holds, :detail, :assertion) do
    def holds? = holds
  end

  def self.call(scorer: EquitableBaseline.new, auditor: nil) = new(scorer: scorer, auditor: auditor).call

  def initialize(scorer:, auditor: nil)
    @scorer = scorer
    @auditor = auditor
  end

  def call
    check = GapInvariance.check(scorer.to_proc, spans: sample_spans)
    assertion = record(check)

    Result.new(policy: policy, criterion: check.criterion, holds: check.holds?,
               detail: check.violation || "score is unchanged when a gap is introduced",
               assertion: assertion)
  end

  private

  attr_reader :scorer, :auditor

  def policy = @policy ||= Policy.find_by!(key: POLICY_KEY)

  def auditor_referent = auditor || Referent.sentinel_for("governance")

  def sample_spans
    start = 10.years.ago
    SAMPLE_KINDS.each_with_index.map do |kind, index|
      from = start + (index * 2).years
      Timeline::Span.new(from: from, to: from + 2.years, relationship: nil, kind: kind)
    end
  end

  # The audit is a claim about the scorer, so it is recorded as one.
  def record(check)
    Assertion.create!(
      asserter: auditor_referent,
      subject: policy,
      act: "assert",
      claim: { "audit" => "policy", "criterion" => check.criterion,
               "scorer" => scorer.class.name, "holds" => check.holds?,
               "baseline" => check.baseline.to_f, "gapped" => check.gapped.to_f }
    )
  end
end
