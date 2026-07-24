# Routing decides which certified model actually answers, so it sits with
# certification rather than with reviewing.
class LlmAssignmentPolicy < ApplicationPolicy
  def index?   = user&.can_view_llm_registry? || false
  def create?  = user&.can_certify_models? || false
  def new?     = create?
  def destroy? = create?
end
