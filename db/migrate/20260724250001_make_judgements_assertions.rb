# Classification and Resolution were both machine-or-human judgements about a
# subject, carrying origin, confidence, rationale and a `current` flag. That is
# an assertion three times over.
#
# Two columns disappear rather than move:
#   origin  -- derivable from asserter.primitive (system vs person)
#   current -- already expressed by `standing` (nothing has superseded it)
#
# Assertions gain a nullable polymorphic `object`: the thing a claim points AT,
# as distinct from the subject it is ABOUT. A classification is about a Claim
# and points at a ClaimCategory; a resolution is about a Mention and points at
# a Referent. Keeping these as references rather than JSON keys preserves
# integrity and lets a referenced record refuse deletion.
class MakeJudgementsAssertions < ActiveRecord::Migration[8.1]
  def up
    add_reference :assertions, :object, polymorphic: true

    # Asserters for migrated judgements. Machine judgements are attributed to a
    # System referent; human ones to a Person referent per distinct name.
    execute <<~SQL.squish
      INSERT INTO referents (system_id, name, subject, role, primitive, key, created_at, updated_at)
      SELECT gen_random_uuid()::text, 'Claim Classifier', 'System', 'Classifier', 'system',
             'claim-classifier', NOW(), NOW()
       WHERE NOT EXISTS (SELECT 1 FROM referents WHERE key = 'claim-classifier')
    SQL

    execute <<~SQL.squish
      INSERT INTO referents (system_id, name, subject, role, primitive, created_at, updated_at)
      SELECT DISTINCT gen_random_uuid()::text, c.classifier, 'Person', 'Reviewer', 'person',
             NOW(), NOW()
        FROM classifications c
       WHERE c.origin = 'human' AND c.classifier IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM referents r WHERE r.name = c.classifier)
    SQL

    execute <<~SQL.squish
      INSERT INTO assertions (asserter_id, subject_type, subject_id, object_type, object_id,
                              act, claim, asserted_at, created_at, updated_at)
      SELECT COALESCE(
               (SELECT r.id FROM referents r WHERE r.name = c.classifier AND c.origin = 'human'),
               (SELECT r.id FROM referents r WHERE r.key = 'claim-classifier')),
             'Claim', c.claim_id, 'ClaimCategory', c.claim_category_id,
             'classify',
             jsonb_strip_nulls(jsonb_build_object('confidence', c.confidence,
                                                  'rationale', c.rationale)),
             c.created_at, c.created_at, c.updated_at
        FROM classifications c
    SQL

    execute <<~SQL.squish
      INSERT INTO assertions (asserter_id, subject_type, subject_id, object_type, object_id,
                              act, claim, asserted_at, created_at, updated_at)
      SELECT (SELECT r.id FROM referents r WHERE r.key = 'identity-sentinel'),
             'Mention', s.mention_id, 'Referent', s.referent_id,
             'resolve',
             jsonb_strip_nulls(jsonb_build_object('confidence', s.confidence,
                                                  'rationale', s.rationale)),
             s.created_at, s.created_at, s.updated_at
        FROM resolutions s
       WHERE EXISTS (SELECT 1 FROM referents r WHERE r.key = 'identity-sentinel')
    SQL

    drop_table :classifications
    drop_table :resolutions
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "origin and current were replaced by asserter attribution and supersession; " \
          "reversing would have to discard the accountable author of every judgement"
  end
end
