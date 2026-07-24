# Grounding a name, or declaring a form not to be a subject, both write
# durable decisions -- one into the graph, one into the extractor's memory.
class MentionPolicy < ApplicationPolicy
  def ground? = user&.can_review? || false
  def ignore? = ground?
end
