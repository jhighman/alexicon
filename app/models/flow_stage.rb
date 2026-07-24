# A stage of the epistemic ladder.
#
# Scoped to a framework because at least four non-identical sequences exist
# across sources -- Interpretation and Meaning swap order between them, and
# some end at Worldview where others end at Action. Rather than pick one and
# lose the others, each framework version carries its own ladder.
class FlowStage < ApplicationRecord
  belongs_to :framework

  validates :key, :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :key, uniqueness: { scope: :framework_id }
end
