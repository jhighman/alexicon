# The move from one claim to the next.
#
# The transition -- not the claim -- is the unit of risk. A claim may be
# perfectly sound; the danger is the unannounced promotion between claims.
#
# `verdict` defaults to undetermined and `score` is nullable so that "we do not
# know yet" is representable. A system that had to choose earned/unearned for
# every pair would be manufacturing the confidence it exists to police.
class Transition < ApplicationRecord
  VERDICTS = %w[earned unearned undetermined].freeze

  belongs_to :document
  belongs_to :from_claim, class_name: "Claim", inverse_of: :outgoing_transitions
  belongs_to :to_claim,   class_name: "Claim", inverse_of: :incoming_transitions
  has_many :sentinel_flags, as: :subject, dependent: :destroy

  validates :verdict, inclusion: { in: VERDICTS }
  validates :score,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  validate  :claims_must_differ

  scope :unearned, -> { where(verdict: "unearned") }

  # True when the categories differ -- a category change, which is what the
  # Sentinel watches for. It says nothing about whether the change was earned.
  def category_change?
    from = from_claim.category
    to   = to_claim.category
    from.present? && to.present? && from != to
  end

  private

  def claims_must_differ
    errors.add(:to_claim, "must differ from from_claim") if from_claim_id.present? && from_claim_id == to_claim_id
  end
end
