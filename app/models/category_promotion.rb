# How much justification a move between two kinds of claim demands.
#
# Seeded data, like the categories themselves, so recalibrating is a seed change
# rather than a migration — and cheap to reverse if it turns out wrong.
#
# `weight` is not a rank difference. It is what the move COSTS:
#
#   0  no promotion at all — a lateral move, or a retreat to firmer ground
#   1  ordinary promotion — meaning assigned to something established
#   2  the move the framework exists to police — meaning becoming a claim
#      about what exists
#   3  both at once, with nothing in between
class CategoryPromotion < ApplicationRecord
  belongs_to :framework
  belongs_to :from_category, class_name: "ClaimCategory"
  belongs_to :to_category, class_name: "ClaimCategory"

  validates :weight, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :from_category_id, uniqueness: { scope: %i[framework_id to_category_id] }

  # The cost of this move, or nil when the framework says nothing about it.
  # Nil is not zero: "no rule for this pair" and "this pair costs nothing" are
  # different, and collapsing them would silently licence unweighted moves.
  def self.weight_for(from:, to:, framework: nil)
    return nil if from.blank? || to.blank?

    framework ||= from.framework
    find_by(framework: framework, from_category: from, to_category: to)&.weight
  end

  def to_s = "#{from_category.key} → #{to_category.key} = #{weight}"
end
