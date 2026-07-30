# A judgement made under one set of premises is not the same judgement made
# under another, and until now the record could not tell them apart.
#
# Every ruling in this database was made under `alexicon-2.0`, whose promotion
# weights encode a Humean premise — `ontological -> normative` costs 2, with a
# rationale naming Hume. A `lewisian-1.0` framework exists that substitutes two
# of those pairs. Running it produced four differing verdicts across 327 steps,
# and those verdicts COULD NOT BE PERSISTED: with no framework on the assertion
# they would have been indistinguishable from the Sentinel being re-run and
# changing its mind. The baseline records that run as `persisted: false` for
# exactly this reason.
#
# Nullable, because most assertions are not made under a framework at all. A
# classification names a category that already belongs to one; a disposal is a
# person's, not a premise's. This is for judgements whose ANSWER depends on
# which framework was asked.
class AddFrameworkToAssertions < ActiveRecord::Migration[8.1]
  def up
    add_reference :assertions, :framework, null: true, foreign_key: true

    # Backfill rather than leave null. Every existing ruling was made under the
    # framework that has been current throughout, and saying so is a statement
    # of fact about the record. Leaving them null would make "unattributed" and
    # "Humean" the same state, which is the confusion this migration removes.
    current = execute("SELECT id FROM frameworks WHERE current = true LIMIT 1").first
    return if current.nil?

    execute(<<~SQL.squish)
      UPDATE assertions
         SET framework_id = #{current['id'].to_i}
       WHERE subject_type = 'Relationship'
         AND claim ->> 'verdict' IS NOT NULL
    SQL
  end

  def down
    remove_reference :assertions, :framework, foreign_key: true
  end
end
