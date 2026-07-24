# An occurrence of an identifier inside a claim -- the unit the Identity
# Sentinel acts on.
#
# `status` is the Sentinel's verdict about the INPUT, not about the world. It
# records whether a referent was established, never who the referent "really"
# is.
class Mention < ApplicationRecord
  STATUSES = %w[unresolved resolved ambiguous out_of_distribution unanchored].freeze

  # Every status other than `resolved` blocks execution. There is no partial
  # credit: a subject is grounded or it is not.
  BLOCKING = (STATUSES - %w[resolved]).freeze

  belongs_to :claim
  has_many :resolutions, dependent: :destroy

  # Flags raised about this mention. NOT dependent: :destroy -- a flag is an
  # immutable assertion, so a mention that has been flagged cannot be deleted
  # without erasing the governance history that explains why it was blocked.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  def flags = assertions.flags.standing.chronological

  validates :text, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :blocking, -> { where(status: BLOCKING) }
  scope :resolved, -> { where(status: "resolved") }

  def resolution
    resolutions.where(current: true).order(
      Arel.sql("CASE origin WHEN 'human' THEN 0 ELSE 1 END")
    ).first
  end

  def referent = resolution&.referent

  def anchored? = status == "resolved"
end
