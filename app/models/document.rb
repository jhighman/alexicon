# A text submitted for analysis. The original body is never mutated -- claims
# reference it by offset, so the source stays auditable.
class Document < ApplicationRecord
  has_many :claims, -> { order(:position) }, dependent: :destroy

  validates :body, presence: true

  def mentions = Mention.where(claim_id: claims.select(:id))

  # Transitions are edges between this document's claims, derived rather than
  # owned -- an edge belongs to its endpoints, not to a container.
  def transitions = Transition.where(source_type: "Claim", source_id: claims.select(:id))

  # Every standing flag raised about anything in this document.
  def flags
    Assertion.flags.standing.where(
      "(assertions.subject_type = 'Relationship' AND assertions.subject_id IN (:rel)) " \
      "OR (assertions.subject_type = 'Mention' AND assertions.subject_id IN (:men))",
      rel: transitions.select(:id), men: mentions.select(:id)
    )
  end

  # A STOP nobody has answered yet. Disposition is derived from assertions
  # about the flag, so this cannot be resolved in SQL alone.
  def open_stops = flags.stopping.select(&:open?)

  # Execution is locked while any STOP stands undisposed. This is the lock the
  # Identity Sentinel applies: not a warning to be read past, but a refusal to
  # proceed until a person resolves the ambiguity.
  def executable? = open_stops.none?

  def blocking_mentions = mentions.blocking

  # The lock has to bite, or it is only a question that downstream code may
  # decline to ask. Reasoning layers call this before proceeding.
  def require_executable!
    return if executable?

    raise ExecutionLocked, "execution locked: #{open_stops.count} unresolved " \
                           "identity flag(s). Unresolved: #{blocking_mentions.pluck(:text).join(', ')}"
  end

  class ExecutionLocked < StandardError; end
end
