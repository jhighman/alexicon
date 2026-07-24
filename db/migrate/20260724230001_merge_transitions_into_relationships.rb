# Relationship and Transition were the same construct at different altitudes:
# a governed edge with its own lifecycle, evidentiary requirements and derived
# standing. Transition additionally stored `verdict` as a column, which is the
# current-state model the Assertion Principle exists to replace.
#
# Merged via STI on `relationships`, with polymorphic endpoints so an edge may
# join Referents (employment) or Claims (an epistemic transition).
class MergeTransitionsIntoRelationships < ActiveRecord::Migration[8.1]
  def up
    add_column    :relationships, :type, :string
    add_column    :relationships, :note, :text
    add_reference :relationships, :source, polymorphic: true
    add_reference :relationships, :target, polymorphic: true

    # Existing relationships become the STI base with Referent endpoints.
    execute <<~SQL.squish
      UPDATE relationships
         SET type = 'Relationship',
             source_type = 'Referent', source_id = source_referent_id,
             target_type = 'Referent', target_id = target_referent_id
    SQL

    # Carry transitions across, remembering where each came from so that
    # flags pointing at them can be repointed.
    add_column :relationships, :legacy_transition_id, :bigint
    execute <<~SQL.squish
      INSERT INTO relationships
        (type, kind, source_type, source_id, target_type, target_id,
         note, legacy_transition_id, created_at, updated_at)
      SELECT 'Transition', 'epistemic_transition',
             'Claim', from_claim_id, 'Claim', to_claim_id,
             note, id, created_at, updated_at
        FROM transitions
    SQL

    # Polymorphic columns store the STI BASE class name, so flags that pointed
    # at 'Transition' must now point at 'Relationship' with the new id.
    execute <<~SQL.squish
      UPDATE sentinel_flags f
         SET flaggable_type = 'Relationship',
             flaggable_id = r.id
        FROM relationships r
       WHERE f.flaggable_type = 'Transition'
         AND r.legacy_transition_id = f.flaggable_id
    SQL
    execute <<~SQL.squish
      UPDATE assertions a
         SET subject_type = 'Relationship', subject_id = r.id
        FROM relationships r
       WHERE a.subject_type = 'Transition'
         AND r.legacy_transition_id = a.subject_id
    SQL

    remove_column :relationships, :legacy_transition_id
    change_column_null :relationships, :source_type, false
    change_column_null :relationships, :source_id, false
    change_column_null :relationships, :target_type, false
    change_column_null :relationships, :target_id, false
    change_column_null :relationships, :type, false

    remove_index  :relationships, name: "index_relationships_on_endpoints_and_kind"
    remove_column :relationships, :source_referent_id
    remove_column :relationships, :target_referent_id
    add_index :relationships, [ :source_type, :source_id, :target_type, :target_id, :kind ],
              name: "index_relationships_on_endpoints_and_kind"

    drop_table :transitions
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "verdict and score were replaced by accountable assertions; " \
          "reversing would have to invent the claims that produced them"
  end
end
