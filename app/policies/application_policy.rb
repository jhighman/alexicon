# Default: signed-in users may read, nobody may write.
#
# Subclasses open specific actions by asking a capability question, never by
# naming a role. If a policy method reads `user.admin?`, the capability it
# actually needs is missing from User — add it there instead.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = user&.can_view? || false
  def show?    = index?
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Absence, not an exception: an unauthorised reader sees nothing rather
    # than an error revealing that something is there.
    def resolve = user ? scope.all : scope.none

    private

    attr_reader :user, :scope
  end
end
