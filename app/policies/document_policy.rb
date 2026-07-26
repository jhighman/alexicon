class DocumentPolicy < ApplicationPolicy
  def create? = user&.can_ingest? || false

  # Running an analysis writes judgements into the graph.
  def classify? = user&.can_review? || false
  def govern?   = classify?

  # Typing claims by hand is a review act: it writes a judgement that outranks
  # every machine reading of the same claim.
  def type_claims? = classify?
end
