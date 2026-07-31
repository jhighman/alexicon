# A grounded subject.
#
# The Cognitive Passport is Name -> Subject -> Roles(standing, >= 1), e.g.
# "Wednesday -> Family -> Sister". A name alone is not an entity; it is a
# label. The passport is what turns a dead node into something an inference
# may attach to.
#
# ROLES ARE ASSERTIONS, not a column (ADR 21). A person is caregiver AND
# engineer AND exhausted AND highly capable, and those do not compete — so a
# role is a standing claim about the referent: attributable, contestable,
# plural by construction, retired by supersession and never deleted. Collapsing
# somebody into one label would mean superseding standing assertions with named
# authors, and the record of doing so would itself be the finding.
#
# The `role` COLUMN is legacy: one unattributed value, recorded before roles
# named their asserter. It is read as such and never written by any runtime
# path — inventing asserters to modernise old rows is what ADR 19 refused.
#
# Lacan supplies the mechanism: the anchoring point (point de capiton) that
# binds an otherwise sliding signifier to a structural position. Without it
# meaning drifts, which is attention-map dispersion by another name.
#
# `system_id` implements object constancy (Mahler): the representation must
# stay stable across affective and contextual fluctuation, sealing the identity
# into a time-invariant state. Without it the system cannot tell whether a
# *claim* changed or the *subject* did -- which is how evidence gets
# manipulated silently. So it is assigned once and frozen.
class Referent < ApplicationRecord
  has_many :referent_aliases, dependent: :destroy
  # Assertions pointing AT this referent -- resolutions, chiefly. A referent
  # something has been resolved to cannot be deleted out from under it.
  has_many :referencing_assertions, class_name: "Assertion", as: :object,
           dependent: :restrict_with_error

  has_many :outgoing_relationships, class_name: "Relationship", as: :source,
           dependent: :restrict_with_error
  has_many :incoming_relationships, class_name: "Relationship", as: :target,
           dependent: :restrict_with_error

  # Assertions this referent has made. Accountability begins with attribution,
  # so every claim traces back to someone who can answer for it.
  has_many :assertions_made, class_name: "Assertion",
           foreign_key: :asserter_id, dependent: :restrict_with_error,
           inverse_of: :asserter

  # Assertions made ABOUT this referent. Restricted for the same reason as
  # assertions_made: the historical record is not deletable.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  def relationships
    Relationship.where(source_type: "Referent", source_id: id)
                .or(Relationship.where(target_type: "Referent", target_id: id))
  end

  # The accountable actor for a domain's flags.
  def self.sentinel_for(domain_key)
    find_by!(key: "#{domain_key}-sentinel")
  end

  # A sentinel is a System referent serving a domain. Flags are attributed to
  # it, because a governance signal with no accountable author is exactly the
  # ungrounded claim the architecture refuses elsewhere.
  belongs_to :domain, optional: true

  # What a referent may be, and what each kind carries (ADR 22): a person's
  # judgements settle claims and may grant delegations; a system's are
  # inferences; an entity's do not exist — places, concepts and family units do
  # not author, and a validation on Assertion closes that path.
  PRIMITIVES = %w[person system entity].freeze

  class RecognitionRefused < StandardError; end

  validates :name, presence: true
  validates :key, uniqueness: true, allow_nil: true
  validates :system_id, presence: true, uniqueness: true
  validate  :system_id_is_immutable, on: :update
  validate  :primitive_changes_only_by_recognition, on: :update

  before_validation :assign_system_id, on: :create

  # --- Roles -----------------------------------------------------------------

  # The standing role assertions, oldest first. The claim key is the filter:
  # other things are asserted about referents (drift audits, notes) and none of
  # them carries "role".
  def role_assertions
    assertions.standing.chronological.select { it.claim.key?("role") }
  end

  # Every role currently standing — the legacy column's unattributed value
  # first (it predates every assertion), then the asserted ones in the order
  # they were made. One entry per distinct role: two people asserting the same
  # role is agreement, not two roles.
  def roles
    [ self[:role].presence, *role_assertions.map { it.claim["role"] } ].compact.uniq
  end

  # The only write path. Recorded beside what stands, never over it.
  def assert_role!(role, by:, rationale: nil)
    payload = { "role" => role }
    payload["rationale"] = rationale if rationale.present?

    assertions.create!(asserter: by, act: "assert", claim: payload)
  end

  # Who says each role, for any surface that shows one. nil means the role is
  # the legacy column's: recorded before roles named their asserter, which is a
  # different fact from "nobody said it" and must not be shown as either
  # asserted or absent.
  def role_attributions
    attributed = role_assertions.group_by { it.claim["role"] }
                                .transform_values { |list| list.map { it.asserter.name } }
    legacy = self[:role].presence
    legacy && !attributed.key?(legacy) ? { legacy => nil }.merge(attributed) : attributed
  end

  def unattributed_role? = self[:role].present?

  # --- Recognition -----------------------------------------------------------
  #
  # `primitive` is authority configuration: it decides whose reading settles a
  # claim and who may grant a delegation. So it is never inferred from a typed
  # string, never flipped by a plain update, and changes only through this —
  # which records who changed it, from what, to what, and why, in the same
  # transaction that writes the column. Certification's shape, applied to
  # referents: authority is granted accountably by a named person, and revoked
  # down the identical path.
  def recognize_as!(kind, by:, rationale:)
    raise ArgumentError, "unknown kind #{kind.inspect}" unless PRIMITIVES.include?(kind.to_s)
    raise RecognitionRefused, "recognition flows only from a person — #{by&.name || 'nobody'} " \
                              "is #{by&.primitive || 'nothing'}, and an agent cannot mint a person" unless
      by&.primitive == "person"

    transaction do
      assertions.create!(asserter: by, act: "assert",
                         claim: { "primitive" => kind.to_s, "was" => primitive,
                                  "rationale" => rationale })
      @recognizing = true
      begin
        update!(primitive: kind.to_s)
      ensure
        @recognizing = false
      end
    end
  end

  # Presentation only — the legacy value, else the earliest asserted role. A
  # spec holds every behavioral path to #roles instead: one label was never a
  # fact to branch on, and now it is not even the record's shape.
  def role = self[:role].presence || role_assertions.first&.claim&.fetch("role", nil)

  # A passport is complete only with all three levels, and the third is now
  # "at least one standing role". A partial passport is not a weaker anchor --
  # it is no anchor, and the Sentinel treats it as such.
  def anchored? = subject.present? && roles.any?

  def passport = [ name, subject, roles.join(" · ").presence ].compact.join(" → ")

  # Every surface form that refers to this entity.
  def surface_forms = [ name, *referent_aliases.pluck(:name) ].uniq

  private

  def assign_system_id
    self.system_id ||= SecureRandom.uuid
  end

  def system_id_is_immutable
    return unless system_id_changed?

    errors.add(:system_id, "is immutable: object constancy requires a stable identity")
  end

  # The silent flip this closes was demonstrated before it was closed: an
  # entity became a person by plain update! and the record showed nothing —
  # neither the flip nor the reversion. A kind that drifts silently is an
  # authority that drifts silently.
  def primitive_changes_only_by_recognition
    return unless primitive_changed?
    return if @recognizing

    errors.add(:primitive, "changes only through recognition — " \
                           "recognize_as!(kind, by:, rationale:)")
  end
end
