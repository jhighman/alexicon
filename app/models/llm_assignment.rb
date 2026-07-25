# A rule saying which model answers for which caller and act.
#
# Matched by glob against the caller's Referent key, so "*-sentinel" can be
# routed differently from "claim-classifier" without naming each one.
#
# Specificity decides between competing rules before priority does: a rule
# naming an action beats one that matches any action, and an exact caller beats
# a pattern. Priority is the tie-break, not the primary key -- otherwise a
# broad rule with a high number silently captures traffic a narrow rule was
# written for.
class LlmAssignment < ApplicationRecord
  belongs_to :llm_model
  belongs_to :created_by, class_name: "Referent", optional: true
  has_many :llm_invocations, dependent: :nullify

  validates :agent_pattern, presence: true
  validates :priority, numericality: { only_integer: true }
  validate  :model_must_be_certified

  scope :active, -> { where(active: true) }
  scope :with_assignable_model, -> { joins(:llm_model).merge(LlmModel.assignable) }

  def matches?(agent_key:, action_type:)
    matches_agent?(agent_key) && matches_action?(action_type)
  end

  def matches_agent?(agent_key)
    return false if agent_key.blank?

    File.fnmatch(agent_pattern, agent_key, File::FNM_PATHNAME)
  end

  def matches_action?(action) = action_type.nil? || action_type == action

  def specificity
    score = 0
    score += 10 if action_type.present?
    score += 1 unless agent_pattern.include?("*")
    score
  end

  def scope_description = "#{agent_pattern} / #{action_type || 'any action'}"

  # A rule can be perfectly well-formed and still route nowhere, because the
  # model beneath it was revoked or its provider switched off. That state is
  # invisible unless it is stated.
  def usable? = active? && llm_model.certified? && llm_model.llm_provider.active?

  def unusable_reason
    return nil if usable?
    return "switched off" unless active?
    return "model revoked" if llm_model.revoked?
    return "model not certified" unless llm_model.certified?

    "#{llm_model.llm_provider.name} inactive"
  end

  private

  # Enforced here as well as in the resolver: an uncertified model must not be
  # reachable, and a rule pointing at one is a trap waiting for someone to
  # certify the wrong thing.
  def model_must_be_certified
    return if llm_model.blank? || llm_model.certified?

    errors.add(:llm_model, "must be certified before it can be assigned")
  end
end
