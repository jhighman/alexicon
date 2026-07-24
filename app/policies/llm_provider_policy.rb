class LlmProviderPolicy < ApplicationPolicy
  def index?  = user&.can_view_llm_registry? || false
  def show?   = index?
  def create? = user&.can_certify_models? || false
  def new?    = create?
  def update? = create?
  def edit?   = create?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can_view_llm_registry? ? scope.all : scope.none
  end
end
