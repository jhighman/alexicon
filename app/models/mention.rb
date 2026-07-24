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
  has_many :sentinel_flags, as: :flaggable, dependent: :destroy

  validates :text, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :blocking, -> { where(status: BLOCKING) }
  scope :resolved, -> { where(status: "resolved") }

  def resolution
    resolutions.where(current: true).order(
      Arel.sql("CASE origin WHEN 'human' THEN 0 ELSE 1 END")
    ).first
  end

  def entity = resolution&.entity

  def anchored? = status == "resolved"
end
