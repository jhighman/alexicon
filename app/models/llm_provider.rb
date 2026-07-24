class LlmProvider < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  # Encrypted at rest, and never rendered back. Filtered from logs by
  # config.filter_parameters, so a stray parameter dump cannot leak it.
  #
  # This protects database dumps, backups, and replicas. It does not protect
  # against someone who already has both the database and config/master.key --
  # at that point they have the application.
  encrypts :api_key

  belongs_to :api_key_set_by, class_name: "Referent", optional: true
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
  def credential_env = adapter&.credential_env

  # A stored key beats the environment. Setting one is a deliberate,
  # attributable act by a named admin looking at this page; an environment
  # variable is ambient. Letting the ambient value win silently would mean an
  # admin sets a key, sees it recorded, and it does nothing.
  #
  # Clearing the stored key falls back to the environment, so the ops path
  # stays available.
  def api_key_in_effect = api_key.presence || env_api_key.presence

  def credentialed? = api_key_in_effect.present?

  def credential_source
    return "stored" if api_key.present?
    return "environment" if env_api_key.present?

    nil
  end

  # Enough to tell two keys apart, not enough to use one.
  def api_key_hint
    key_value = api_key_in_effect
    return nil if key_value.blank?

    "…#{key_value.last(4)}"
  end

  def set_api_key!(value, by:)
    update!(api_key: value, api_key_set_at: Time.current, api_key_set_by: by)
  end

  def clear_api_key!
    update!(api_key: nil, api_key_set_at: nil, api_key_set_by: nil)
  end

  private

  def env_api_key = credential_env ? ENV[credential_env] : nil
end
