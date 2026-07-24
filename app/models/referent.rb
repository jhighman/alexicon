# A grounded subject.
#
# The Cognitive Passport is Name -> Subject -> Role, e.g.
# "Wednesday -> Family -> Sister". A name alone is not an entity; it is a
# label. The passport is what turns a dead node into something an inference
# may attach to.
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
  has_many :resolutions, dependent: :restrict_with_error
  has_many :mentions, through: :resolutions

  validates :name, presence: true
  validates :system_id, presence: true, uniqueness: true
  validate  :system_id_is_immutable, on: :update

  before_validation :assign_system_id, on: :create

  # A passport is complete only with all three levels. A partial passport is
  # not a weaker anchor -- it is no anchor, and the Sentinel treats it as such.
  def anchored? = subject.present? && role.present?

  def passport = [ name, subject, role ].compact.join(" → ")

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
end
