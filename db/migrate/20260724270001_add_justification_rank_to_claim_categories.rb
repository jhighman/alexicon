# Categories are "not hierarchical in value -- they are different in kind".
# But the ladder does increase abstraction, and "every step requires more
# evidence". Those are two different orderings, and conflating them would make
# the Sentinel rank claims by worth rather than by justification burden.
#
# `position` is presentation order. `justification_rank` is how much warrant a
# claim of that kind requires. Objective and Observation share a rank: neither
# outranks the other, and merging them is an error of kind, not of degree.
class AddJustificationRankToClaimCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :claim_categories, :justification_rank, :integer
  end
end
