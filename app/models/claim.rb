# One individually classifiable statement within a document.
class Claim < ApplicationRecord
  belongs_to :document
  has_many :mentions, dependent: :destroy

  # Classifications are assertions about this claim. NOT dependent: :destroy --
  # a judgement is immutable historical record.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  has_many :outgoing_transitions, class_name: "Transition", as: :source,
           dependent: :restrict_with_error
  has_many :incoming_transitions, class_name: "Transition", as: :target,
           dependent: :restrict_with_error

  validates :text, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  def classifications = assertions.acting("classify").standing.chronological

  # The live classification. A person's judgement wins over a system's, but the
  # system's is retained rather than overwritten -- the framework's own axiom
  # applied to its own output.
  def classification
    candidates = classifications.includes(:asserter).to_a
    candidates.select(&:human?).last || candidates.last
  end

  def category = classification&.object

  # Records a classification as an accountable assertion.
  def classify!(category, asserter:, confidence: nil, rationale: nil, supersedes: nil)
    payload = {}
    payload["confidence"] = confidence if confidence
    payload["rationale"] = rationale if rationale

    assertions.create!(asserter: asserter, act: "classify", object: category,
                       claim: payload, supersedes: supersedes)
  end
end
