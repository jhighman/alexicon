# A judgement about what kind of claim something is.
#
# Deliberately its own record rather than a column on Claim. A machine
# classification is an INFERENCE, and the framework's axiom forbids inference
# becoming evidence -- including the system's own. So origin is recorded, a
# human judgement never overwrites the machine's, and both remain auditable.
class Classification < ApplicationRecord
  ORIGINS = %w[model human].freeze

  belongs_to :claim
  belongs_to :claim_category

  validates :origin, inclusion: { in: ORIGINS }
  validates :confidence,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true

  scope :current, -> { where(current: true) }
  scope :by_model, -> { where(origin: "model") }
  scope :by_human, -> { where(origin: "human") }

  def inferred? = origin == "model"
end
