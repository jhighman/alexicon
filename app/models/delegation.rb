# A standing decision that an agent's judgement counts for a particular act.
#
# This is the hinge the whole agent surface turns on. Without it an agent may
# read and propose; with it, a named person has said in advance that a class of
# judgement may be made without them — and the record shows who said so, for
# which act, and why.
#
# That is the difference between delegating judgement and bypassing it. The
# person does not stop deciding; they decide once, about a class, instead of
# repeatedly about instances. Governing the policy rather than the case is the
# whole of what "operating at a wisdom layer" can be made to mean without
# vanishing into metaphor.
#
# Absence of a row is refusal. Nothing is delegated by default, and a delegation
# is revoked by deactivating it rather than by deletion, so the record of what
# was once permitted survives.
class Delegation < ApplicationRecord
  # The acts a person can be asked to perform, and therefore the only ones that
  # can be delegated. Deliberately not `Assertion::ACTS`: these are review
  # decisions, not every mark that can be made on the record.
  ACTS = %w[
    dispose_flag
    ground_mention
    ignore_mention
    certify_model
    revoke_model
  ].freeze

  belongs_to :granted_by, class_name: "Referent"

  validates :agent_pattern, presence: true
  validates :act, inclusion: { in: ACTS }

  normalizes :agent_pattern, with: ->(pattern) { pattern.to_s.strip }

  scope :active, -> { where(active: true) }

  # Whether some agent may make this judgement now.
  def self.permits?(referent:, act:)
    return false if referent.blank? || referent.key.blank?

    live.any? { it.covers?(referent: referent, act: act) }
  end

  def self.live
    active.where(act: ACTS).select(&:current?)
  end

  def current? = active? && (expires_at.nil? || expires_at.future?)

  def covers?(referent:, act:)
    return false unless current?
    return false unless self.act == act.to_s

    File.fnmatch(agent_pattern, referent.key.to_s, File::FNM_PATHNAME)
  end

  def scope_description = "#{agent_pattern} may #{act.humanize.downcase}"
end
