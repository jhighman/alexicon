# A grounded subject.
#
# The Cognitive Passport is Name -> Category -> Role. A name alone is not an
# entity; it is a label. The passport is what turns a dead node into something
# an inference may attach to.
#
# `system_id` implements object constancy (Mahler): the representation must
# stay stable across affective and contextual fluctuation. Without it the
# system cannot tell whether a *claim* changed or the *subject* did -- which is
# how evidence gets manipulated silently. So it is assigned once and frozen.
class Entity < ApplicationRecord
  has_many :entity_aliases, dependent: :destroy
  has_many :resolutions, dependent: :restrict_with_error
  has_many :mentions, through: :resolutions

  validates :name, presence: true
  validates :system_id, presence: true, uniqueness: true
  validate  :system_id_is_immutable, on: :update

  before_validation :assign_system_id, on: :create

  # A passport is complete only with all three levels. A partial passport is
  # not a weaker anchor -- it is no anchor, and the Sentinel treats it as such.
  def anchored? = category.present? && role.present?

  def passport = [ name, category, role ].compact.join(" → ")

  # Every surface form that refers to this entity.
  def surface_forms = [ name, *entity_aliases.pluck(:name) ].uniq

  private

  def assign_system_id
    self.system_id ||= SecureRandom.uuid
  end

  def system_id_is_immutable
    return unless system_id_changed?

    errors.add(:system_id, "is immutable: object constancy requires a stable identity")
  end
end
