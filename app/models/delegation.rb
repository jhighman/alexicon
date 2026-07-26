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
#
# --- TEI inversion -----------------------------------------------------------
#
# Alexandra Krížová's rule, applied here: authority TIGHTENS the justification
# required of it rather than loosening it. The instinct in most systems runs the
# other way — a powerful actor is trusted further and asked for less — and that
# is exactly the path by which a covert policy gets installed one reasonable
# command at a time.
#
# So the wider the pattern and the heavier the act, the more a delegation must
# carry to exist at all: a rationale, then an expiry, then a bounded one. A
# narrow delegation of a light act needs none of that. Nothing here makes a
# powerful delegation impossible; it makes one unable to be made quietly.
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
    type_claim
  ].freeze

  # What the act costs if it is wrong. Certification is heaviest because it
  # decides which model may influence any judgement at all; disposing a flag is
  # next because it lifts a STOP.
  ACT_WEIGHT = {
    # An agent's blind reading is recorded and moves nothing: it is excluded
    # from the classifier's tally by construction, so the worst a wrong one does
    # is put a bad second opinion in the comparison. The lightest act there is.
    "type_claim" => 1,
    "ground_mention" => 1,
    "ignore_mention" => 1,
    "dispose_flag" => 2,
    "revoke_model" => 2,
    "certify_model" => 3
  }.freeze

  RATIONALE_REQUIRED_AT = 2
  EXPIRY_REQUIRED_AT = 3
  MAX_LIFETIME = 30.days

  belongs_to :granted_by, class_name: "Referent"

  validates :agent_pattern, presence: true
  validates :act, inclusion: { in: ACTS }
  validate  :granted_by_must_be_a_person
  validate  :heavier_delegations_must_say_why
  validate  :heavier_delegations_must_expire

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

  # How much of the graph this reaches. A bare "*" is every agent there will
  # ever be, including ones nobody has created yet.
  def breadth
    return 2 if agent_pattern == "*"
    return 1 if agent_pattern.include?("*")

    0
  end

  def act_weight = ACT_WEIGHT.fetch(act.to_s, 1)

  # Consequence times reach. What the delegation must carry rises with it.
  def scrutiny = act_weight + breadth

  def rationale_required? = scrutiny >= RATIONALE_REQUIRED_AT
  def expiry_required?    = scrutiny >= EXPIRY_REQUIRED_AT

  def scope_description = "#{agent_pattern} may #{act.humanize.downcase}"

  private

  # An agent cannot widen its own authority, or another agent's. Only a person
  # delegates — otherwise the whole arrangement is a system granting itself
  # permissions and recording that a decision was made.
  def granted_by_must_be_a_person
    return if granted_by.blank? || granted_by.primitive == "person"

    errors.add(:granted_by, "must be a person — an agent cannot delegate judgement, " \
                            "to itself or to another agent")
  end

  def heavier_delegations_must_say_why
    return if rationale.present? || !rationale_required?

    errors.add(:rationale, "is required for #{scope_description} — this delegation reaches " \
                           "#{breadth.zero? ? 'one agent' : 'a family of agents'} with an act " \
                           "weighted #{act_weight}, and a standing permission that heavy should " \
                           "record why it was granted")
  end

  def heavier_delegations_must_expire
    return unless expiry_required?

    if expires_at.blank?
      errors.add(:expires_at, "is required for #{scope_description} — a permission this " \
                              "broad should have to be renewed deliberately rather than " \
                              "outlive the reason it was granted")
    elsif expires_at > MAX_LIFETIME.from_now
      errors.add(:expires_at, "cannot be more than #{MAX_LIFETIME.inspect} away for " \
                              "#{scope_description}")
    end
  end
end
