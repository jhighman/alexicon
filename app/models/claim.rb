# One individually classifiable statement within a document.
class Claim < ApplicationRecord
  belongs_to :document
  has_many :classifications, dependent: :destroy
  has_many :outgoing_transitions, class_name: "Transition", foreign_key: :from_claim_id, dependent: :destroy, inverse_of: :from_claim
  has_many :incoming_transitions, class_name: "Transition", foreign_key: :to_claim_id, dependent: :destroy, inverse_of: :to_claim

  validates :text, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  # The live classification. Human disposition wins over machine, but the
  # machine's judgement is retained rather than overwritten.
  def classification
    classifications.where(current: true).order(
      Arel.sql("CASE origin WHEN 'human' THEN 0 ELSE 1 END")
    ).first
  end

  def category = classification&.claim_category
end
