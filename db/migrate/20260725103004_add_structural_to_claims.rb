# A heading is part of the document but is not a claim about anything.
#
# Marked rather than dropped: the text stays in the record and still renders, so
# nothing is hidden. What changes is that nothing asks it what kind of claim it
# is, and no step is drawn through it — a heading is where an argument restarts,
# not a move within one.
class AddStructuralToClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :claims, :structural, :boolean, null: false, default: false
    add_index :claims, :structural
  end
end
