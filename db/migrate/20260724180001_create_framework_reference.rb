# The framework is reference DATA, not constants. It has already moved from
# G3/G7 to 2.0, and its vocabulary has drifted repeatedly. Versioned rows mean
# a new domain or a renamed metric is a seed change, not a migration.
class CreateFrameworkReference < ActiveRecord::Migration[8.1]
  def change
    create_table :frameworks do |t|
      t.string :key,     null: false
      t.string :name,    null: false
      t.string :version, null: false
      t.boolean :current, null: false, default: false
      t.text :notes
      t.timestamps
    end
    add_index :frameworks, :key, unique: true

    # The seven domains. Ordered, but the ordering is not enforced as a
    # dependency -- no source asserts a hard stack, only a sequence.
    create_table :domains do |t|
      t.references :framework, null: false, foreign_key: true
      t.string  :key,      null: false
      t.string  :name,     null: false
      t.integer :position, null: false
      t.text    :question, null: false
      t.text    :summary
      t.timestamps
    end
    add_index :domains, [ :framework_id, :key ],      unique: true
    add_index :domains, [ :framework_id, :position ], unique: true

    create_table :domain_components do |t|
      t.references :domain, null: false, foreign_key: true
      t.string  :name,     null: false
      t.integer :position, null: false
      t.timestamps
    end

    # What a domain protects against.
    create_table :domain_failure_modes do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name, null: false
      t.text   :description
      t.timestamps
    end

    # Objective / Observation / Interpretive / Ontological.
    # A different axis from domains: category = kind of claim,
    # domain = kind of check.
    create_table :claim_categories do |t|
      t.references :framework, null: false, foreign_key: true
      t.string  :key,               null: false
      t.string  :name,              null: false
      t.integer :position,          null: false
      t.text    :definition,        null: false
      t.string  :confidence_source, null: false
      t.timestamps
    end
    add_index :claim_categories, [ :framework_id, :key ], unique: true

    # The epistemic ladder. Versioned because at least four non-identical
    # sequences exist across sources; each framework row carries its own.
    create_table :flow_stages do |t|
      t.references :framework, null: false, foreign_key: true
      t.string  :key,      null: false
      t.string  :name,     null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :flow_stages, [ :framework_id, :key ],      unique: true
    add_index :flow_stages, [ :framework_id, :position ], unique: true
  end
end
