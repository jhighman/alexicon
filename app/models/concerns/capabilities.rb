# What an actor may do, as one set of questions asked of anything that acts.
#
# Both a signed-in person and an API token answer these. Keeping one
# implementation is the point: two copies drift, and a capability that means
# something different depending on who is asking is not a capability.
#
# Roles are deliberately few. A long role list encodes job titles rather than
# capabilities, and then every policy has to know the titles.
module Capabilities
  extend ActiveSupport::Concern

  ROLES = %w[admin auditor reviewer viewer].freeze

  def admin?    = role == "admin"
  def auditor?  = role == "auditor"
  def reviewer? = role == "reviewer"

  # Reading the work: documents, claims, flags.
  def can_view? = true

  # Answering a flag, grounding a name, marking a form as not a subject.
  # These write accountable judgements into the graph.
  def can_review? = admin? || reviewer?

  # Submitting new text for analysis, and running the analysis.
  def can_ingest? = admin? || reviewer?

  # Seeing which models exist, what they cost, and what they were asked.
  def can_view_llm_registry? = admin? || auditor?

  # Deciding that a model may influence judgements at all.
  def can_certify_models? = admin?

  # Whether this actor's judgement counts as a person's. An API token held by
  # an agent answers false however wide its role, and no capability changes
  # that: the record must never say a person decided when one did not.
  def human? = referent&.primitive == "person"
end
