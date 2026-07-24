# Terminology has drifted at least four times across sources. The register is
# stored rather than documented so that renames are data, and so that a
# disputed term can be marked disputed instead of silently picked.
class CreateTerminology < ActiveRecord::Migration[8.1]
  def change
    create_table :terms do |t|
      t.string :key,            null: false
      t.string :canonical_name, null: false
      t.string :kind                                  # protocol, metric, failure_mode, mechanism
      t.string :status, null: false, default: "active" # active | disputed | superseded
      t.text   :notes
      t.timestamps
    end
    add_index :terms, :key, unique: true

    create_table :term_aliases do |t|
      t.references :term, null: false, foreign_key: true
      t.string :name,   null: false
      t.string :source                                 # where the alias appears
      t.text   :note
      t.timestamps
    end
    add_index :term_aliases, :name
  end
end
