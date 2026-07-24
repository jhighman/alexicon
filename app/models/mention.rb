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

  # Resolutions and flags are both assertions about this mention. NOT
  # dependent: :destroy -- deleting would erase the governance history that
  # explains why the mention was blocked.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  validates :text, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :blocking, -> { where(status: BLOCKING) }
  scope :resolved, -> { where(status: "resolved") }

  def flags = assertions.flags.standing.chronological

  def resolutions = assertions.acting("resolve").standing.chronological

  # A person's resolution wins over a system's, without erasing it.
  def resolution
    candidates = resolutions.includes(:asserter).to_a
    candidates.select(&:human?).last || candidates.last
  end

  def referent = resolution&.object

  def anchored? = status == "resolved"
end
