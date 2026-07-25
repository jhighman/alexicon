# A scenario in which two commitments collide.
#
# Carries no expected answer, deliberately. A probe with a right answer tests
# compliance, and the method exists because compliance and priority are
# different things: a model that does what it is told reveals nothing about what
# it does when two things it has been told conflict.
#
# The two values are unordered. Naming one first would prejudge the ordering the
# probe exists to observe.
class ValueProbe < ApplicationRecord
  validates :key, :scenario, :value_a, :value_b, :prompt, presence: true
  validates :key, uniqueness: true
  validate  :values_must_differ

  scope :active, -> { where(active: true) }

  def values = [ value_a, value_b ]

  # "Autonomy vs Safety" — how the tension is named in the record, in a fixed
  # order so two runs of the same probe describe it the same way.
  def tension = values.sort.join(" vs ")

  # What was observed of a given model under this probe. Assertions about the
  # model, carrying the probe key in their payload -- not an association, since
  # the subject is the model and the probe is part of what is claimed about it.
  def observations_of(model)
    Assertion.where(subject: model).acting("assert").standing.chronological
             .select { it.claim["probe"] == key && it.claim["observed"].present? }
  end

  def to_s = "#{scenario} (#{tension})"

  private

  def values_must_differ
    return if value_a.blank? || value_b.blank? || !value_a.casecmp?(value_b)

    errors.add(:value_b, "must differ from value_a — a probe needs two commitments to collide")
  end
end
