# Authorisation, and its link to the graph.
#
# Alexicon already had accountable identities: a Referent with primitive
# "person". What it lacked was any check on who may act. "Identify yourself"
# established a name and nothing else — anyone could dispose of any flag.
#
# A User carries the credential and the role; its Referent carries the
# provenance. Every judgement is still attributed to the Referent, so the
# audit trail is unchanged — authorisation is added beside it, not on top of
# it. One identity, two concerns.
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "viewer"

      # The graph identity this person acts as. Judgements attribute here.
      t.references :referent, null: false, foreign_key: true

      t.timestamps
    end
    add_index :users, "LOWER(username)", unique: true, name: "index_users_on_lower_username"
    add_index :users, :role
  end
end
