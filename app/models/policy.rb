# A cross-cutting constraint binding several domains without belonging to any.
#
# The anti-discrimination protocol is the motivating case: it touches Identity,
# Reflection and Governance, and making it an eighth domain would break a
# published seven-domain structure.
class Policy < ApplicationRecord
  has_many :domain_policies, dependent: :destroy
  has_many :domains, through: :domain_policies

  # Audits recorded against this policy. A policy nothing has ever been
  # checked against is a statement of intent, not a constraint.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  validates :key, :name, :statement, presence: true
  validates :key, uniqueness: true

  def audits = assertions.acting("assert").standing.chronological.select { it.claim["audit"] == "policy" }

  def last_audit = audits.last

  def enforced? = last_audit&.claim&.fetch("holds", false) || false
end
