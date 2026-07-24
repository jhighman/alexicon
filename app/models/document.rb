# A text submitted for analysis. The original body is never mutated -- claims
# reference it by offset, so the source stays auditable.
class Document < ApplicationRecord
  has_many :claims, -> { order(:position) }, dependent: :destroy
  has_many :transitions, dependent: :destroy

  validates :body, presence: true

  def mentions = Mention.where(claim_id: claims.select(:id))

  def flags
    SentinelFlag
      .where(subject_type: "Transition", subject_id: transitions.select(:id))
      .or(SentinelFlag.where(subject_type: "Mention", subject_id: mentions.select(:id)))
  end

  # Execution is locked while any STOP stands undisposed. This is the lock the
  # Identity Sentinel applies: not a warning to be read past, but a refusal to
  # proceed until a person resolves the ambiguity.
  def executable? = flags.open.stopping.none?

  def blocking_mentions = mentions.blocking

  # The lock has to bite, or it is only a question that downstream code may
  # decline to ask. Reasoning layers call this before proceeding.
  def require_executable!
    return if executable?

    raise ExecutionLocked, "execution locked: #{flags.open.stopping.count} unresolved " \
                           "identity flag(s). Unresolved: #{blocking_mentions.pluck(:text).join(', ')}"
  end

  class ExecutionLocked < StandardError; end
end
