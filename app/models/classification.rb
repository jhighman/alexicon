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

  # Identity verification precedes reasoning. Nothing may be predicated of an
  # ungrounded subject, so a claim in a document with open identity STOPs
  # cannot be classified at all.
  #
  # Agency is preserved: a person may dispose of the flag and proceed. What
  # they may not do is reason past it silently.
  validate :execution_must_not_be_locked, on: :create

  scope :current, -> { where(current: true) }
  scope :by_model, -> { where(origin: "model") }
  scope :by_human, -> { where(origin: "human") }

  def inferred? = origin == "model"

  private

  def execution_must_not_be_locked
    return if claim.blank? || claim.document.blank? || claim.document.executable?

    errors.add(:base,
               "execution is locked: unresolved identity in this document must be " \
               "cleared before a claim may be classified")
  end
end
