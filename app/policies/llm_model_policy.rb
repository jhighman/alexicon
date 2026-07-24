# Certification decides which model may influence any judgement at all, so it
# is the narrowest capability in the system.
class LlmModelPolicy < ApplicationPolicy
  def index?   = user&.can_view_llm_registry? || false
  def show?    = index?
  def create?  = user&.can_certify_models? || false
  def new?     = create?
  def certify? = create?
  def revoke?  = certify?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can_view_llm_registry? ? scope.all : scope.none
  end
end
