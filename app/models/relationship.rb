# The fifth primitive.
#
# A relationship is not metadata attached to two referents. It is an
# independently governable object with its own lifecycle, authority, and
# evidentiary requirements. "Sarah works for Acme" cannot be reduced to Sarah
# or to Acme -- yet it ceases to exist if either endpoint is removed.
#
# Note what this class does NOT have: a status column, a valid_from, an
# `active` boolean. Those would be current state, and current state conceals
# the sequence of accountable claims through which it emerged. Everything
# about this relationship's standing is DERIVED from its assertions.
#
# Consequently a relationship can be genuinely disputed -- two contradictory
# claims, neither resolved -- and the model represents that rather than
# forcing a winner.
class Relationship < ApplicationRecord
  STATUSES = %i[proposed active disputed revoked expired].freeze

  belongs_to :source_referent, class_name: "Referent"
  belongs_to :target_referent, class_name: "Referent"

  # NOT dependent: :destroy. Assertions are immutable historical record, so a
  # relationship that has been asserted about cannot be deleted -- it is
  # revoked. Deleting it would erase the accountable claims rather than answer
  # them, which is the failure the Assertion Principle exists to prevent.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  validates :kind, presence: true
  validate  :endpoints_must_differ

  def history = assertions.chronological

  # Claims that nothing later has superseded. Several may stand at once, and
  # they may contradict each other. That is not a defect.
  def standing_assertions = assertions.standing.chronological

  # Derived standing. Order matters: revocation ends a relationship outright,
  # an unanswered challenge leaves it disputed rather than active, and expiry
  # is only meaningful once something asserted it in the first place.
  def status(at: Time.current)
    return :proposed if standing_assertions.none?
    return :revoked  if standing_assertions.acting("revoke").any?
    return :disputed if disputed?
    return :expired  if established_assertions(at: at).none? && ever_established?

    established_assertions(at: at).any? ? :active : :proposed
  end

  def active?(at: Time.current) = status(at: at) == :active

  # A challenge with no standing answer after it. Disagreement is preserved
  # until an accountable actor resolves it, not silently reconciled.
  def disputed? = standing_assertions.acting("challenge").any?

  # The claim currently carrying authority: the most recent standing
  # assert/amend whose validity window covers the moment.
  def current_claim(at: Time.current) = established_assertions(at: at).last&.claim

  def evidence = Evidence.joins(:evidence_links)
                         .where(evidence_links: { assertion_id: assertions.select(:id) })
                         .distinct

  private

  def established_assertions(at:)
    standing_assertions.select { it.act.in?(%w[assert amend]) && it.covers?(at) }
  end

  def ever_established?
    standing_assertions.any? { it.act.in?(%w[assert amend]) }
  end

  def endpoints_must_differ
    return if source_referent_id.blank? || source_referent_id != target_referent_id

    errors.add(:target_referent, "must differ from source_referent")
  end
end
