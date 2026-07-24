# Governance over which model may influence downstream reasoning.
#
# The Sentinel Principle applied to model selection: a model does not get to
# affect any judgement until a named person has certified it. Before this, the
# model was a constant in a class with nobody's name on it.
#
# Adapted from a reference architecture (ttb/trua-collect) in three ways:
# actors are Referents rather than Users, since Alexicon already has accountable
# identities in the graph; there is no tenant scope; and invocations are
# immutable, because here the audit IS the record rather than telemetry beside
# it.
class CreateLlmGovernance < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_providers do |t|
      t.string :key,    null: false
      t.string :name,   null: false
      t.string :status, null: false, default: "active"   # active | inactive
      t.text   :notes
      t.timestamps
    end
    add_index :llm_providers, :key, unique: true

    create_table :llm_models do |t|
      t.references :llm_provider, null: false, foreign_key: true
      t.string  :model_identifier, null: false            # e.g. claude-opus-5
      t.string  :display_name,     null: false
      t.decimal :cost_per_1k_input,  precision: 12, scale: 6
      t.decimal :cost_per_1k_output, precision: 12, scale: 6

      # pending -> certified -> revoked. Only certified models are assignable.
      t.string :certification_status, null: false, default: "pending"
      t.references :certified_by, foreign_key: { to_table: :referents }
      t.datetime :certified_at
      t.datetime :revoked_at
      t.text     :revocation_reason
      t.timestamps
    end
    add_index :llm_models, [ :llm_provider_id, :model_identifier ], unique: true
    add_index :llm_models, :certification_status

    # A declarative rule: which model answers for which caller and act.
    create_table :llm_assignments do |t|
      t.references :llm_model, null: false, foreign_key: true
      t.string  :agent_pattern, null: false     # glob against Referent#key
      t.string  :action_type                    # nil matches any
      t.integer :priority, null: false, default: 0
      t.boolean :active,   null: false, default: true
      t.references :created_by, foreign_key: { to_table: :referents }
      t.timestamps
    end
    add_index :llm_assignments, :active

    # One row per call. Immutable, and written in the same transaction as the
    # assertion it produced -- a lost invocation would be a hole in provenance.
    create_table :llm_invocations do |t|
      t.references :llm_model,      null: false, foreign_key: true
      t.references :llm_assignment, foreign_key: true
      t.references :agent,          null: false, foreign_key: { to_table: :referents }
      t.references :assertion,      foreign_key: true   # what the call produced, if anything

      t.integer :input_tokens,  null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens,  null: false, default: 0
      t.decimal :cost_usd, precision: 12, scale: 6, null: false, default: 0
      t.integer :latency_ms

      t.string :status, null: false          # success | error | timeout
      t.text   :error_message
      t.string :action_type
      t.timestamps
    end
    add_index :llm_invocations, :status
    add_index :llm_invocations, :created_at
  end
end
