# A model, and whether anyone has vouched for it.
#
# `pending -> certified -> revoked`. A model may not be assigned, and therefore
# may not influence any judgement, until a named person certifies it. This is
# the Sentinel Principle applied to model selection: the transformation does
# not get to run because it exists, but because someone accountable said it may.
#
# Revocation is terminal. A model whose behaviour proved unacceptable should
# not be quietly re-certified under the same identity -- register the
# replacement instead, so the record of why it was withdrawn stays legible.
class LlmModel < ApplicationRecord
  STATUSES = %w[pending certified revoked].freeze

  belongs_to :llm_provider
  belongs_to :certified_by, class_name: "Referent", optional: true
  has_many :llm_assignments, dependent: :restrict_with_error
  has_many :llm_invocations, dependent: :restrict_with_error

  validates :model_identifier, :display_name, presence: true
  validates :model_identifier, uniqueness: { scope: :llm_provider_id }
  validates :certification_status, inclusion: { in: STATUSES }
  validate  :certification_needs_an_author
  validate  :provider_must_be_invocable_to_certify

  scope :certified, -> { where(certification_status: "certified") }
  scope :pending,   -> { where(certification_status: "pending") }
  scope :revoked,   -> { where(certification_status: "revoked") }

  # Certified, from a provider that is still switched on.
  scope :assignable, -> { certified.joins(:llm_provider).merge(LlmProvider.active) }

  def certified? = certification_status == "certified"
  def revoked?   = certification_status == "revoked"

  def certify!(referent)
    raise ArgumentError, "a revoked model cannot be re-certified" if revoked?

    update!(certification_status: "certified", certified_by: referent, certified_at: Time.current)
  end

  def revoke!(reason:, by: nil)
    update!(certification_status: "revoked", revoked_at: Time.current,
            revocation_reason: reason, certified_by: by || certified_by)
  end

  # Cost of a call, from the model's own published rates.
  def cost_for(input_tokens:, output_tokens:)
    ((cost_per_1k_input || 0) * input_tokens / 1000.0) +
      ((cost_per_1k_output || 0) * output_tokens / 1000.0)
  end

  def client = llm_provider.adapter&.new(self)

  def invocable? = llm_provider.invocable?

  def to_s = display_name

  private

  # Certifying a model whose provider has no adapter would vouch for something
  # the code cannot call. The registry must not promise what it cannot do.
  def provider_must_be_invocable_to_certify
    return unless certified?
    return if llm_provider&.invocable?

    errors.add(:llm_provider, "has no adapter — this application cannot call it, " \
                              "so certifying it would claim a capability it does not have")
  end

  # "Certified" with nobody's name on it is the same as uncertified.
  def certification_needs_an_author
    return unless certified?
    return if certified_by.present?

    errors.add(:certified_by, "is required — certification has to be somebody's decision")
  end
end
