class DocumentPolicy < ApplicationPolicy
  def create? = user&.can_ingest? || false

  # Running an analysis writes judgements into the graph.
  def classify? = user&.can_review? || false
  def govern?   = classify?
end
