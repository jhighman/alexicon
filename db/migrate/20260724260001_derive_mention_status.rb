# The last piece of stored state.
#
# `mentions.status` was a cache of a derived value, kept in step by hand inside
# the Sentinel's transaction. A cache that can drift from the record it
# summarises is exactly the current-state model the rest of this schema has
# been removing.
#
# Status is now read from the mention's standing judgements: a standing
# `resolve` means resolved; a standing `flag` carries which Entity Noise
# condition was detected; neither means nothing has looked yet.
class DeriveMentionStatus < ActiveRecord::Migration[8.1]
  def up
    # Backfill the noise condition onto existing flags, so the status they
    # imply survives the column's removal.
    execute <<~SQL.squish
      UPDATE assertions a
         SET claim = a.claim || jsonb_build_object('noise', m.status)
        FROM mentions m
       WHERE a.subject_type = 'Mention'
         AND a.subject_id = m.id
         AND a.act = 'flag'
         AND m.status <> 'resolved'
         AND a.claim->>'noise' IS NULL
    SQL

    remove_column :mentions, :status
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "status is derived from standing judgements; restoring the column " \
          "would reintroduce a cache that can disagree with the record"
  end
end
