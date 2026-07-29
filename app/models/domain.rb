# One of the seven domains of epistemic governance. Each carries a governing
# question and the failure modes it protects against.
#
# `position` records the order the domains are presented in. It is deliberately
# NOT modelled as a dependency: no source asserts that a domain strictly
# requires the one below it, only that they are listed in sequence.
class Domain < ApplicationRecord
  # The Motivation domain has listed Values among its components since the
  # framework was seeded; this is where they actually live.
  has_many :framework_values, -> { ordered }, dependent: :destroy, inverse_of: :domain

  alias_method :values, :framework_values

  belongs_to :framework
  has_many :domain_components, -> { order(:position) }, dependent: :destroy
  has_many :domain_failure_modes, dependent: :destroy
  has_many :domain_policies, dependent: :destroy
  has_many :policies, through: :domain_policies
  # Sentinels serving this domain. A flag is attributed to one of them.
  has_many :sentinels, class_name: "Referent", dependent: :nullify

  validates :key, :name, :question, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :key, uniqueness: { scope: :framework_id }

  def components = domain_components.pluck(:name)
  def protects_against = domain_failure_modes.pluck(:name)
end
