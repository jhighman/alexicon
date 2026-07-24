class LlmProvider < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  has_many :llm_models, dependent: :restrict_with_error

  validates :key, :name, presence: true
  validates :key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def active? = status == "active"

  # The registry may list any provider, but only one with an adapter can be
  # called. Listing without this distinction would let an admin certify and
  # route to a model the code cannot reach.
  def adapter = LlmClients.for(key)
  def invocable? = adapter.present?
  def credentialed? = adapter&.credentialed? || false
  def credential_env = adapter&.credential_env
end
