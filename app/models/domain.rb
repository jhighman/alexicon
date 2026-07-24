# One of the seven domains of epistemic governance. Each carries a governing
# question and the failure modes it protects against.
#
# `position` records the order the domains are presented in. It is deliberately
# NOT modelled as a dependency: no source asserts that a domain strictly
# requires the one below it, only that they are listed in sequence.
class Domain < ApplicationRecord
  belongs_to :framework
  has_many :domain_components, -> { order(:position) }, dependent: :destroy
  has_many :domain_failure_modes, dependent: :destroy
  has_many :domain_policies, dependent: :destroy
  has_many :policies, through: :domain_policies
  has_many :sentinel_flags, dependent: :nullify

  validates :key, :name, :question, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :key, uniqueness: { scope: :framework_id }

  def components = domain_components.pluck(:name)
  def protects_against = domain_failure_modes.pluck(:name)
end
