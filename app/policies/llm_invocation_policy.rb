# Invocations are written by services, never by people. There is no action a
# user can take on one, so every write verb is closed rather than guarded.
class LlmInvocationPolicy < ApplicationPolicy
  def index? = user&.can_view_llm_registry? || false
  def show?  = index?

  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can_view_llm_registry? ? scope.all : scope.none
  end
end
