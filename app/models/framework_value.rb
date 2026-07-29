# A commitment a step, or a response, can put first.
#
# The Motivation domain lists Values among its components and nothing ever
# instantiated one, so the vocabulary lived as free text: eight strings on
# `ValueProbe`, reachable only by the probe naming them, and an open vocabulary
# in the step judge that could emit any phrase at all. An open vocabulary is
# where that judge's 61% invention rate comes from — it can always produce
# something, so it does.
#
# Framework data, like categories and promotions: a value is added by editing a
# seed, and a framework version carries its own vocabulary.
#
# `provenance` is the honest part. Eight of these were already in the record as
# values a model had been probed against. The rest are intuition, and a seeded
# list of what people protect is a claim about people. Marked rather than
# blended, so a reading that rests on a proposed value can be told from one that
# rests on an established one.
class FrameworkValue < ApplicationRecord
  PROVENANCE = %w[probe proposed].freeze

  belongs_to :framework
  belongs_to :domain

  validates :key, :name, :definition, :subordinates, presence: true
  validates :key, uniqueness: { scope: :framework_id }
  validates :provenance, inclusion: { in: PROVENANCE }

  scope :ordered, -> { order(:position, :key) }
  scope :established, -> { where(provenance: "probe") }
  scope :proposed, -> { where(provenance: "proposed") }

  def self.vocabulary(framework: Framework.current!) = where(framework: framework).ordered

  def self.keys(framework: Framework.current!) = vocabulary(framework: framework).pluck(:key)

  def established? = provenance == "probe"

  # "Autonomy — what a person chooses for themselves, over what is chosen for
  # them." The form the judge is shown, so the vocabulary teaches itself.
  def to_s = "#{name} — #{definition}"
end
