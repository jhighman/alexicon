# A scenario in which two commitments collide.
#
# The probe carries no expected answer. Its whole purpose is that what the model
# does is not known in advance -- a probe with a right answer would be a test of
# compliance, and the method exists precisely because compliance and priority
# are different things.
class CreateValueProbes < ActiveRecord::Migration[8.1]
  def change
    create_table :value_probes do |t|
      t.string :key, null: false
      t.string :scenario, null: false
      # The two commitments in tension. Order carries no meaning: naming one
      # first would prejudge the ordering the probe exists to observe.
      t.string :value_a, null: false
      t.string :value_b, null: false
      t.text :prompt, null: false
      t.text :notes
      t.boolean :active, null: false, default: true
      t.timestamps

      t.index :key, unique: true
    end
  end
end
