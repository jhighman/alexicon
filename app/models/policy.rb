# A cross-cutting constraint binding several domains without belonging to any.
#
# The anti-discrimination protocol is the motivating case: it touches Identity,
# Reflection and Governance, and making it an eighth domain would break a
# published seven-domain structure.
class Policy < ApplicationRecord
  has_many :domain_policies, dependent: :destroy
  has_many :domains, through: :domain_policies

  validates :key, :name, :statement, presence: true
  validates :key, uniqueness: true
end
