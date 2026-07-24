# Objective / Observation / Interpretive / Ontological.
#
# These are different in KIND, not in rank -- position is presentation order,
# never precedence. Merging them is the error the system exists to catch.
class ClaimCategory < ApplicationRecord
  belongs_to :framework
  has_many :classifications, dependent: :restrict_with_error

  validates :key, :name, :definition, :confidence_source, presence: true
  validates :key, uniqueness: { scope: :framework_id }
end
