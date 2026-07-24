# Cross-cutting constraints that bind multiple domains without belonging to
# any one of them. The anti-discrimination protocol is the motivating case:
# it touches Identity, Reflection and Governance and lives in none.
class CreatePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :policies do |t|
      t.string :key,       null: false
      t.string :name,      null: false
      t.text   :statement, null: false
      t.text   :rationale
      t.timestamps
    end
    add_index :policies, :key, unique: true

    create_table :domain_policies do |t|
      t.references :policy, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.timestamps
    end
    add_index :domain_policies, [ :policy_id, :domain_id ], unique: true
  end
end
