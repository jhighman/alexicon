# A rule whose action_type is "" reads as "any act" everywhere it is displayed
# and matches no act at all, so it routes nothing while looking correct. The
# form's blank option was storing exactly that.
#
# The model now normalises blanks to NULL; this repairs rows written before it
# did. A CHECK constraint keeps the empty string out for good, since this is a
# failure that hides rather than announces itself.
class NormalizeBlankActionTypeOnLlmAssignments < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE llm_assignments SET action_type = NULL WHERE action_type = ''"

    add_check_constraint :llm_assignments, "action_type <> ''",
                         name: "llm_assignments_action_type_not_empty"
  end

  def down
    remove_check_constraint :llm_assignments, name: "llm_assignments_action_type_not_empty"
  end
end
