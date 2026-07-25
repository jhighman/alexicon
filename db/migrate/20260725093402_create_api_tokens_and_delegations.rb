# Non-human actors, and the terms on which their judgement counts.
#
# A token belongs to a REFERENT, not to a user session. That is the whole point:
# whatever acts through the API attributes its assertions to itself, so an agent
# driving the sentinels can never leave a record saying a person decided.
#
# A delegation says which acts an agent's judgement may satisfy. Absence of a
# row is refusal — an agent with no delegation may read and propose and nothing
# else, which is the posture the system starts in.
class CreateApiTokensAndDelegations < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.references :referent, null: false, foreign_key: true
      t.string :name, null: false
      # The secret is never stored. Only its digest, and enough of the plaintext
      # to tell two tokens apart in a list.
      t.string :token_digest, null: false
      t.string :hint, null: false
      t.string :role, null: false, default: "viewer"
      t.references :issued_by, foreign_key: { to_table: :referents }
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.string :revocation_reason
      t.timestamps

      t.index :token_digest, unique: true
    end

    create_table :delegations do |t|
      # Glob, matched against the acting referent's key, so "*-agent" can be
      # delegated without naming each one.
      t.string :agent_pattern, null: false
      t.string :act, null: false
      t.references :granted_by, null: false, foreign_key: { to_table: :referents }
      t.text :rationale
      t.boolean :active, null: false, default: true
      t.datetime :expires_at
      t.timestamps

      t.index %i[agent_pattern act]
    end
  end
end
