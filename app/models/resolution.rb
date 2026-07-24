# A judgement that a mention refers to an entity.
#
# The same discipline as Classification: a machine resolution is an inference
# and is recorded as one. A human may resolve differently; the machine's
# judgement is retained rather than overwritten.
class Resolution < ApplicationRecord
  ORIGINS = %w[model human].freeze

  belongs_to :mention
  belongs_to :entity

  validates :origin, inclusion: { in: ORIGINS }
  validates :confidence,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true

  scope :current, -> { where(current: true) }
  scope :by_model, -> { where(origin: "model") }
  scope :by_human, -> { where(origin: "human") }

  def inferred? = origin == "model"
end
