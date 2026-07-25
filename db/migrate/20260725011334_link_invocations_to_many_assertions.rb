# One call can now produce several judgements.
#
# Classification used to send one claim per call, so an invocation pointed at
# the single assertion it produced. Sending a batch with document context makes
# that one-to-one link false, and a false audit link is worse than a coarse one
# -- "this judgement came from that call" has to stay answerable.
#
# So the link moves to the assertion side, where it can be many.
class LinkInvocationsToManyAssertions < ActiveRecord::Migration[8.1]
  def up
    add_reference :assertions, :llm_invocation, foreign_key: true, null: true

    execute <<~SQL
      UPDATE assertions
         SET llm_invocation_id = llm_invocations.id
        FROM llm_invocations
       WHERE llm_invocations.assertion_id = assertions.id
    SQL

    remove_reference :llm_invocations, :assertion, foreign_key: true
  end

  def down
    add_reference :llm_invocations, :assertion, foreign_key: true, null: true

    execute <<~SQL
      UPDATE llm_invocations
         SET assertion_id = assertions.id
        FROM assertions
       WHERE assertions.llm_invocation_id = llm_invocations.id
    SQL

    remove_reference :assertions, :llm_invocation, foreign_key: true
  end
end
