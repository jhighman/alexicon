# Entity resolution: the input boundary.
#
# A name arrives as an "empty dead node" -- no properties, no bindings, no
# context. Nothing may be predicated of it until it resolves to a grounded
# entity. Guessing the referent is exactly how an inference becomes evidence.
class CreateEntities < ActiveRecord::Migration[8.1]
  def change
    # The Cognitive Passport: Name -> Category -> Role.
    #
    # `system_id` is the object-constancy guarantee (Mahler): a stable handle
    # that survives affective and contextual fluctuation. It is assigned once
    # and never reassigned -- enforced in the model.
    create_table :entities do |t|
      t.string :system_id, null: false
      t.string :name,      null: false
      t.string :category                       # Family, Organisation, Concept, ...
      t.string :role                           # Sister, Employer, ...
      t.text   :notes
      t.timestamps
    end
    add_index :entities, :system_id, unique: true
    add_index :entities, :name

    create_table :entity_aliases do |t|
      t.references :entity, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :source
      # True when this surface form is known to carry non-entity senses too
      # ("Wednesday" the weekday). Such a form never resolves silently.
      t.boolean :ambiguous, null: false, default: false
      t.timestamps
    end
    add_index :entity_aliases, :name

    # An occurrence of an identifier in a claim -- the thing to be resolved.
    create_table :mentions do |t|
      t.references :claim, null: false, foreign_key: true
      t.string  :text, null: false
      t.integer :char_start
      t.integer :char_end
      # unresolved | resolved | ambiguous | out_of_distribution | unanchored
      t.string  :status, null: false, default: "unresolved"
      t.timestamps
    end
    add_index :mentions, :status

    # Mirrors `classifications`: a resolver judgement is an INFERENCE. Origin is
    # recorded, and a human correction never overwrites the machine's.
    create_table :resolutions do |t|
      t.references :mention, null: false, foreign_key: true
      t.references :entity,  null: false, foreign_key: true
      t.string  :origin, null: false            # model | human
      t.string  :resolver
      t.decimal :confidence, precision: 5, scale: 4
      t.text    :rationale
      t.boolean :current, null: false, default: true
      t.timestamps
    end
    add_index :resolutions, [ :mention_id, :current ]
  end
end
