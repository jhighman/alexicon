# The Motivation domain has always listed its components as
# ["Purpose", "Values", "Intent"], and `components` is an array of strings —
# decoration rather than entities. So the framework has said all along that
# values live under Motivation, and nothing instantiated one.
#
# A partial vocabulary already existed, on `ValueProbe`: Autonomy, Safety,
# Truth, Kindness, Curiosity, Privacy, Expression, Harm reduction. Eight values,
# reachable only by the probe that names them, so what a MODEL prioritises under
# conflict and what a TEXT's step puts first were incomparable by construction.
#
# This promotes them to framework data, seeded and versioned like categories and
# promotions, and gives the two value layers one vocabulary.
#
# `framework_values` rather than `values`: VALUES is reserved in SQL, and a
# table that has to be quoted everywhere is a table somebody will eventually
# forget to quote.
class CreateFrameworkValues < ActiveRecord::Migration[8.1]
  def change
    create_table :framework_values do |t|
      t.references :framework, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :definition, null: false
      # What putting this first typically sets aside. A value with nothing to
      # subordinate is not a commitment, it is a preference.
      t.text :subordinates, null: false
      # Where this entry came from. "probe" was already in the record as a value
      # a model was tested against; "proposed" is intuition, and a seeded list
      # of what people protect is a claim about people that should say so.
      t.string :provenance, null: false, default: "proposed"
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :framework_values, %i[framework_id key], unique: true
    add_check_constraint :framework_values, "provenance IN ('probe', 'proposed')",
                         name: "framework_values_provenance"
  end
end
