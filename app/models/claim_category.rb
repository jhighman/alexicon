# Objective / Observation / Interpretive / Ontological.
#
# These are different in KIND, not in rank -- position is presentation order,
# never precedence. Merging them is the error the system exists to catch.
# `justification_rank` is a property of the CATEGORY: how much warrant a claim
# of this kind needs to stand on its own. What a MOVE between two categories
# costs is a different question, answered by CategoryPromotion — three ranks
# across four categories cannot distinguish "meaning assigned to a fact" from
# "meaning becoming a claim about what exists".
#
# So rank answers "how grounded is this claim", weight answers "what did this
# step cost". Reflection asks the first; Governance and the audit ask the second.
class ClaimCategory < ApplicationRecord
  belongs_to :framework
  # Classifications pointing at this category are assertions.
  has_many :classifications, class_name: "Assertion", as: :object, dependent: :restrict_with_error

  validates :key, :name, :definition, :confidence_source, presence: true
  validates :key, uniqueness: { scope: :framework_id }
end
