# An accountable claim, made by someone, at a time, about a subject.
#
# An assertion is an EVENT, not a property of an object. It records that a
# claim WAS MADE. It does not record that the claim was correct -- an assertion
# may be perfectly authentic and entirely mistaken, and the architecture must
# be able to hold both facts at once.
#
# Immutability is the point. Issuing an assertion enlarges the historical
# record without destroying what preceded it, so the architecture preserves
# disagreement rather than resolving it prematurely. An error is not erased.
# It is ANSWERED -- by a later assertion that references it.
#
# A Sentinel flag is an assertion too: a sentinel claiming that the conditions
# for proceeding have not been satisfied. Its disposition is a further
# assertion about it, which is why "open" is the ABSENCE of a disposition
# rather than a stored default.
class Assertion < ApplicationRecord
  # What the assertion does to its subject.
  ACTS = %w[assert amend revoke challenge delegate flag accept reject].freeze
  DISPOSING = %w[accept reject].freeze
  SEVERITIES = %w[notice concern stop].freeze

  belongs_to :asserter, class_name: "Referent"
  belongs_to :subject, polymorphic: true
  belongs_to :supersedes, class_name: "Assertion", optional: true
  has_many :superseded_by, class_name: "Assertion", foreign_key: :supersedes_id,
                           dependent: :nullify, inverse_of: :supersedes

  # Assertions made ABOUT this assertion -- challenges, corroborations,
  # revocations, dispositions. This is what makes the structure recursive.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  has_many :evidence_links, dependent: :destroy
  has_many :evidence, through: :evidence_links

  validates :act, inclusion: { in: ACTS }
  validates :asserted_at, presence: true
  validate  :validity_window_ordered
  validate  :flag_severity_recognised

  before_validation :stamp_asserted_at, on: :create

  scope :chronological, -> { order(:asserted_at, :id) }
  scope :acting, ->(act) { where(act: act) }
  # An assertion that nothing later has replaced.
  scope :standing, -> { where.missing(:superseded_by) }

  scope :flags, -> { acting("flag") }
  # Qualified: `claim` is ambiguous once this is joined against other tables.
  scope :stopping, -> { flags.where("assertions.claim->>'severity' = ?", "stop") }

  # Enforced immutability. Rails refuses to save changes to a readonly record,
  # so an assertion cannot be revised after the fact -- only answered.
  def readonly? = persisted?

  def supersedes?(other) = supersedes_id == other.id

  # Whether the claim purports to hold at a given moment. Distinct from
  # whether it is believed, which is a question for the subject's status.
  def covers?(moment)
    return false if valid_from.present? && moment < valid_from
    return false if valid_until.present? && moment > valid_until

    true
  end

  # --- Flags -----------------------------------------------------------------
  #
  # A flag NEVER asserts that a claim is false, or that an author is wrong. It
  # asserts that the conditions for proceeding have not been satisfied.

  def flag? = act == "flag"
  def severity = claim["severity"]
  def message  = claim["message"]

  # A STOP is a healthy freeze, not a failure. Dissonance signals that the
  # conditions for proceeding were not met.
  def stop? = flag? && severity == "stop"

  # Derived from the standing disposition assertions about this flag. Absence
  # of one means open -- nobody has answered it yet.
  def disposition
    latest = assertions.standing.chronological.select { it.act.in?(DISPOSING) }.last
    return "open" if latest.nil?

    latest.act == "accept" ? "accepted" : "rejected"
  end

  def open? = disposition == "open"

  # Agency is preserved: a person may accept or reject any flag. Their
  # judgement is recorded ALONGSIDE the flag rather than overwriting it, and
  # is itself attributable and challengeable.
  def dispose!(as:, by:)
    disposing_act = { "accepted" => "accept", "rejected" => "reject" }[as.to_s]
    raise ArgumentError, "unknown disposition #{as}" if disposing_act.nil?

    assertions.create!(asserter: by, act: disposing_act, claim: { "disposition" => as.to_s })
  end

  private

  def stamp_asserted_at
    self.asserted_at ||= Time.current
  end

  def validity_window_ordered
    return if valid_from.blank? || valid_until.blank? || valid_until >= valid_from

    errors.add(:valid_until, "cannot precede valid_from")
  end

  def flag_severity_recognised
    return unless act == "flag"
    return if SEVERITIES.include?(claim["severity"])

    errors.add(:claim, "severity must be one of #{SEVERITIES.join(', ')}")
  end
end
