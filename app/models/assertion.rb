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
class Assertion < ApplicationRecord
  # What the assertion does to its subject.
  ACTS = %w[assert amend revoke challenge delegate].freeze

  belongs_to :asserter, class_name: "Referent"
  belongs_to :subject, polymorphic: true
  belongs_to :supersedes, class_name: "Assertion", optional: true
  has_many :superseded_by, class_name: "Assertion", foreign_key: :supersedes_id,
                           dependent: :nullify, inverse_of: :supersedes

  # Assertions made ABOUT this assertion -- challenges, corroborations,
  # revocations. This is what makes the structure recursive.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  has_many :evidence_links, dependent: :destroy
  has_many :evidence, through: :evidence_links

  validates :act, inclusion: { in: ACTS }
  validates :asserted_at, presence: true
  validate  :validity_window_ordered

  before_validation :stamp_asserted_at, on: :create

  scope :chronological, -> { order(:asserted_at, :id) }
  scope :acting, ->(act) { where(act: act) }
  # An assertion that nothing later has replaced.
  scope :standing, -> { where.missing(:superseded_by) }

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

  private

  def stamp_asserted_at
    self.asserted_at ||= Time.current
  end

  def validity_window_ordered
    return if valid_from.blank? || valid_until.blank? || valid_until >= valid_from

    errors.add(:valid_until, "cannot precede valid_from")
  end
end
