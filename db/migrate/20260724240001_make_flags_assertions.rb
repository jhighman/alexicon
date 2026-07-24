# A flag is a claim about a subject, made by a sentinel: "the conditions for
# proceeding have not been satisfied." That is an assertion.
#
# Disposition was a mutable column, which overwrote governance history. It
# becomes an assertion ABOUT the flag assertion, using the recursion assertions
# already support. "open" is then the absence of a disposition rather than a
# stored default.
#
# Flags also gain what they never had: an accountable asserter. Sentinels
# become System referents bound to the domain they serve.
class MakeFlagsAssertions < ActiveRecord::Migration[8.1]
  def up
    # Stable lookup key for seeded referents (sentinels), and the domain a
    # sentinel serves.
    add_column    :referents, :key, :string
    add_index     :referents, :key, unique: true
    add_reference :referents, :domain, foreign_key: true

    # Carry existing flags across, attributed to a sentinel referent derived
    # from the flag's domain. Flags with no domain go to a generic sentinel.
    execute <<~SQL.squish
      INSERT INTO referents (system_id, name, subject, role, primitive, key, domain_id,
                             created_at, updated_at)
      SELECT gen_random_uuid()::text,
             COALESCE(d.name, 'Unattributed') || ' Sentinel',
             'System', 'Sentinel', 'system',
             COALESCE(d.key, 'unattributed') || '-sentinel',
             d.id, NOW(), NOW()
        FROM (SELECT DISTINCT domain_id FROM sentinel_flags) f
        LEFT JOIN domains d ON d.id = f.domain_id
       WHERE NOT EXISTS (
         SELECT 1 FROM referents r
          WHERE r.key = COALESCE(d.key, 'unattributed') || '-sentinel')
    SQL

    execute <<~SQL.squish
      INSERT INTO assertions (asserter_id, subject_type, subject_id, act, claim,
                              asserted_at, created_at, updated_at)
      SELECT r.id, f.flaggable_type, f.flaggable_id, 'flag',
             jsonb_build_object('severity', f.severity, 'message', f.message),
             f.created_at, f.created_at, f.updated_at
        FROM sentinel_flags f
        LEFT JOIN domains d ON d.id = f.domain_id
        JOIN referents r ON r.key = COALESCE(d.key, 'unattributed') || '-sentinel'
    SQL

    # Dispositions become assertions about those flag assertions.
    execute <<~SQL.squish
      INSERT INTO assertions (asserter_id, subject_type, subject_id, act, claim,
                              asserted_at, created_at, updated_at)
      SELECT r.id, 'Assertion', a.id,
             CASE f.disposition WHEN 'accepted' THEN 'accept' ELSE 'reject' END,
             jsonb_build_object('disposed_by', COALESCE(f.disposed_by, 'unknown')),
             COALESCE(f.disposed_at, f.updated_at), NOW(), NOW()
        FROM sentinel_flags f
        LEFT JOIN domains d ON d.id = f.domain_id
        JOIN referents r ON r.key = COALESCE(d.key, 'unattributed') || '-sentinel'
        JOIN assertions a ON a.subject_type = f.flaggable_type
                         AND a.subject_id = f.flaggable_id
                         AND a.act = 'flag'
       WHERE f.disposition <> 'open'
    SQL

    drop_table :sentinel_flags
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "dispositions became accountable assertions; reversing would collapse " \
          "a history of who disposed of what back into a single mutable column"
  end
end
