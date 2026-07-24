class LlmProvider < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  has_many :llm_models, dependent: :restrict_with_error

  validates :key, :name, presence: true
  validates :key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def active? = status == "active"
end
