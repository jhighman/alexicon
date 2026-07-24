# Flags were bound to transitions, because Governance was the only sentinel.
# The Identity Sentinel flags mentions, and later domains will flag other
# things again. One flag table, many subjects.
class MakeSentinelFlagsPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_reference :sentinel_flags, :subject, polymorphic: true, index: true

    execute <<~SQL.squish
      UPDATE sentinel_flags
         SET subject_type = 'Transition', subject_id = transition_id
       WHERE transition_id IS NOT NULL
    SQL

    change_column_null :sentinel_flags, :subject_type, false
    change_column_null :sentinel_flags, :subject_id, false
    remove_reference :sentinel_flags, :transition, foreign_key: true
  end

  def down
    add_reference :sentinel_flags, :transition, foreign_key: true

    execute <<~SQL.squish
      UPDATE sentinel_flags
         SET transition_id = subject_id
       WHERE subject_type = 'Transition'
    SQL

    remove_reference :sentinel_flags, :subject, polymorphic: true
  end
end
