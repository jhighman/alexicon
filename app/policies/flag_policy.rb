# Answering a flag is a judgement, and it is recorded against the answerer.
class FlagPolicy < ApplicationPolicy
  def update? = user&.can_review? || false
end
