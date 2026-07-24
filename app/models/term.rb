# The terminology register, stored rather than documented.
#
# Names in this framework have drifted repeatedly across sources. A `disputed`
# status lets a term be recorded as contested instead of silently resolved --
# which is the same discipline the system applies to claims.
class Term < ApplicationRecord
  STATUSES = %w[active disputed superseded].freeze

  has_many :term_aliases, dependent: :destroy

  validates :key, :canonical_name, presence: true
  validates :key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :disputed, -> { where(status: "disputed") }
end
