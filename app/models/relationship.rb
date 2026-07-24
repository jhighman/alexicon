# A governed edge.
#
# The thesis's fifth primitive: not metadata attached to two nodes, but an
# independently governable object with its own lifecycle, authority and
# evidentiary requirements. "Sarah works for Acme" cannot be reduced to Sarah
# or to Acme, yet ceases to exist if either endpoint is removed.
#
# Endpoints are polymorphic because the same governance applies whatever they
# join. A Relationship connects Referents; a Transition (subclass) connects
# Claims. This widens the thesis's Chapter 3 primitive, which speaks only of
# connections between primitives -- see ADR 0006.
#
# Note what this class does NOT have: a status column, a verdict, an `active`
# boolean. Those would be current state, and current state conceals the
# sequence of accountable claims through which it emerged. Standing is DERIVED
# from assertions, which is what lets a relationship be genuinely disputed --
# two contradictory claims, neither resolved -- instead of forcing a winner.
class Relationship < ApplicationRecord
  STATUSES = %i[proposed active disputed revoked expired].freeze
  ESTABLISHING = %w[assert amend].freeze

  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  # NOT dependent: :destroy. Assertions are immutable historical record, so an
  # edge that has been asserted about cannot be deleted -- it is revoked.
  # Deleting would erase accountable claims rather than answer them.
  has_many :assertions, as: :subject, dependent: :restrict_with_error
  has_many :sentinel_flags, as: :flaggable, dependent: :destroy

  validates :kind, presence: true
  validate  :endpoints_must_differ

  # Rails leaves the STI column NULL for base-class rows. Writing it keeps the
  # column honest, so "what kind of edge is this?" is answerable in SQL without
  # treating NULL as a meaning.
  before_validation :ensure_type

  def history = assertions.chronological

  # Claims that nothing later has superseded. Several may stand at once, and
  # they may contradict each other. That is not a defect.
  def standing_assertions = assertions.standing.chronological

  # Derived standing. Order matters: revocation ends an edge outright, an
  # unanswered challenge leaves it disputed rather than active, and expiry is
  # only meaningful once something established it in the first place.
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

  # The claim currently carrying authority.
  def current_claim(at: Time.current) = established_assertions(at: at).last&.claim

  def evidence
    Evidence.joins(:evidence_links)
            .where(evidence_links: { assertion_id: assertions.select(:id) })
            .distinct
  end

  private

  def ensure_type
    self[:type] ||= self.class.sti_name
  end

  def established_assertions(at:)
    standing_assertions.select { it.act.in?(ESTABLISHING) && it.covers?(at) }
  end

  def ever_established?
    standing_assertions.any? { it.act.in?(ESTABLISHING) }
  end

  def endpoints_must_differ
    return if source_id.blank?
    return unless source_type == target_type && source_id == target_id

    errors.add(:target, "must differ from source")
  end
end
