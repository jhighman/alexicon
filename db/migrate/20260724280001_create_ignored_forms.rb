# A surface form a person has judged not to be a subject at all.
#
# The extractor proposes candidates structurally, and structure cannot tell
# "Ketamine" from "Alec" -- both are capitalised words it has never seen. That
# distinction needs world knowledge, so it is asked of a person once and
# remembered, rather than guessed at every time.
#
# Recorded with who decided and why: this is a judgement, and judgements here
# carry an author.
class CreateIgnoredForms < ActiveRecord::Migration[8.1]
  def change
    create_table :ignored_forms do |t|
      t.string :form, null: false
      t.text   :reason
      t.references :decided_by, foreign_key: { to_table: :referents }
      t.timestamps
    end
    add_index :ignored_forms, "LOWER(form)", unique: true, name: "index_ignored_forms_on_lower_form"
  end
end
