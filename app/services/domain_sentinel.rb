# Shared shape for a domain sentinel.
#
# A sentinel is not a validator. It does not produce knowledge and does not
# decide; it asks whether the conditions for proceeding have been satisfied,
# and it must be able to actually check something. A sentinel that fires on
# everything, or on nothing it can observe, is ceremonial governance -- the
# thesis's own fourth failure mode, and worse here than having no sentinel at
# all, because it looks like coverage.
#
# So every subclass must name a real, checkable condition. Where a domain has
# no observable at this scale, it is left unimplemented and said so, rather
# than given a detector that detects nothing.
#
# Severity is `notice` or `concern`. Only Identity halts execution, because
# only Identity establishes the ground the others stand on.
class DomainSentinel
  Finding = Data.define(:subject, :message, :severity)

  class << self
    def domain_key = raise(NotImplementedError, "#{name} must name its domain")

    def review!(document) = new(document).review!

    # Every domain sentinel that has an observable to check.
    def all = [ Sentinels::Agency, Sentinels::Motivation, Sentinels::Reflection,
                Sentinels::Integration, Sentinels::Orientation ]

    def review_all!(document) = all.flat_map { it.review!(document) }
  end

  def initialize(document)
    @document = document
  end

  def review!
    document.require_executable!

    findings.map { raise_flag(it) }
  end

  private

  attr_reader :document

  # Subclasses return an array of Finding.
  def findings = raise(NotImplementedError)

  def claims = @claims ||= document.claims.to_a

  def sentinel = @sentinel ||= Referent.sentinel_for(self.class.domain_key)

  def domain = @domain ||= sentinel.domain

  # The flag carries the domain's governing question, so the reader sees what
  # was being asked rather than only that something fired.
  def raise_flag(finding)
    Assertion.create!(
      asserter: sentinel,
      subject: finding.subject,
      act: "flag",
      claim: { "severity" => finding.severity,
               "message" => "#{finding.message} (#{domain&.question})" }
    )
  end

  # Has this subject already been flagged by this sentinel? Sentinels are
  # re-runnable; they should not accumulate duplicates.
  def already_flagged?(subject)
    Assertion.flags.standing
             .where(asserter: sentinel, subject_type: subject.class.base_class.name,
                    subject_id: subject.id).exists?
  end
end
