# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_25_115526) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "hint", null: false
    t.bigint "issued_by_id"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.bigint "referent_id", null: false
    t.string "revocation_reason"
    t.datetime "revoked_at"
    t.string "role", default: "viewer", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["issued_by_id"], name: "index_api_tokens_on_issued_by_id"
    t.index ["referent_id"], name: "index_api_tokens_on_referent_id"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
  end

  create_table "assertions", force: :cascade do |t|
    t.string "act", default: "assert", null: false
    t.datetime "asserted_at", null: false
    t.bigint "asserter_id", null: false
    t.jsonb "claim", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "llm_invocation_id"
    t.bigint "object_id"
    t.string "object_type"
    t.text "provenance"
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.bigint "supersedes_id"
    t.datetime "updated_at", null: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.index ["act"], name: "index_assertions_on_act"
    t.index ["asserter_id"], name: "index_assertions_on_asserter_id"
    t.index ["llm_invocation_id"], name: "index_assertions_on_llm_invocation_id"
    t.index ["object_type", "object_id"], name: "index_assertions_on_object"
    t.index ["subject_type", "subject_id", "asserted_at"], name: "idx_on_subject_type_subject_id_asserted_at_f9911a1d7d"
    t.index ["subject_type", "subject_id"], name: "index_assertions_on_subject"
    t.index ["supersedes_id"], name: "index_assertions_on_supersedes_id"
  end

  create_table "claim_categories", force: :cascade do |t|
    t.string "confidence_source", null: false
    t.datetime "created_at", null: false
    t.text "definition", null: false
    t.bigint "framework_id", null: false
    t.integer "justification_rank"
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["framework_id", "key"], name: "index_claim_categories_on_framework_id_and_key", unique: true
    t.index ["framework_id"], name: "index_claim_categories_on_framework_id"
  end

  create_table "claims", force: :cascade do |t|
    t.integer "char_end"
    t.integer "char_start"
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.integer "position", null: false
    t.boolean "structural", default: false, null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "position"], name: "index_claims_on_document_id_and_position", unique: true
    t.index ["document_id"], name: "index_claims_on_document_id"
    t.index ["structural"], name: "index_claims_on_structural"
  end

  create_table "delegations", force: :cascade do |t|
    t.string "act", null: false
    t.boolean "active", default: true, null: false
    t.string "agent_pattern", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "granted_by_id", null: false
    t.text "rationale"
    t.datetime "updated_at", null: false
    t.index ["agent_pattern", "act"], name: "index_delegations_on_agent_pattern_and_act"
    t.index ["granted_by_id"], name: "index_delegations_on_granted_by_id"
  end

  create_table "documents", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "source_kind"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "domain_components", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_domain_components_on_domain_id"
  end

  create_table "domain_failure_modes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "domain_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_domain_failure_modes_on_domain_id"
  end

  create_table "domain_policies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.bigint "policy_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_domain_policies_on_domain_id"
    t.index ["policy_id", "domain_id"], name: "index_domain_policies_on_policy_id_and_domain_id", unique: true
    t.index ["policy_id"], name: "index_domain_policies_on_policy_id"
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "framework_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.text "question", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["framework_id", "key"], name: "index_domains_on_framework_id_and_key", unique: true
    t.index ["framework_id", "position"], name: "index_domains_on_framework_id_and_position", unique: true
    t.index ["framework_id"], name: "index_domains_on_framework_id"
  end

  create_table "evidence", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", null: false
    t.datetime "obtained_at"
    t.string "reference"
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_evidence_on_kind"
  end

  create_table "evidence_links", force: :cascade do |t|
    t.bigint "assertion_id", null: false
    t.datetime "created_at", null: false
    t.bigint "evidence_id", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["assertion_id", "evidence_id"], name: "index_evidence_links_on_assertion_id_and_evidence_id", unique: true
    t.index ["assertion_id"], name: "index_evidence_links_on_assertion_id"
    t.index ["evidence_id"], name: "index_evidence_links_on_evidence_id"
  end

  create_table "flow_stages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "framework_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["framework_id", "key"], name: "index_flow_stages_on_framework_id_and_key", unique: true
    t.index ["framework_id", "position"], name: "index_flow_stages_on_framework_id_and_position", unique: true
    t.index ["framework_id"], name: "index_flow_stages_on_framework_id"
  end

  create_table "frameworks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "current", default: false, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["key"], name: "index_frameworks_on_key", unique: true
  end

  create_table "ignored_forms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "decided_by_id"
    t.string "form", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index "lower((form)::text)", name: "index_ignored_forms_on_lower_form", unique: true
    t.index ["decided_by_id"], name: "index_ignored_forms_on_decided_by_id"
  end

  create_table "llm_assignments", force: :cascade do |t|
    t.string "action_type"
    t.boolean "active", default: true, null: false
    t.string "agent_pattern", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "llm_model_id", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_llm_assignments_on_active"
    t.index ["created_by_id"], name: "index_llm_assignments_on_created_by_id"
    t.index ["llm_model_id"], name: "index_llm_assignments_on_llm_model_id"
    t.check_constraint "action_type::text <> ''::text", name: "llm_assignments_action_type_not_empty"
  end

  create_table "llm_invocations", force: :cascade do |t|
    t.string "action_type"
    t.bigint "agent_id", null: false
    t.decimal "cost_usd", precision: 12, scale: 6, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "input_tokens", default: 0, null: false
    t.integer "latency_ms"
    t.bigint "llm_assignment_id"
    t.bigint "llm_model_id", null: false
    t.integer "output_tokens", default: 0, null: false
    t.string "status", null: false
    t.integer "total_tokens", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_llm_invocations_on_agent_id"
    t.index ["created_at"], name: "index_llm_invocations_on_created_at"
    t.index ["llm_assignment_id"], name: "index_llm_invocations_on_llm_assignment_id"
    t.index ["llm_model_id"], name: "index_llm_invocations_on_llm_model_id"
    t.index ["status"], name: "index_llm_invocations_on_status"
  end

  create_table "llm_models", force: :cascade do |t|
    t.string "certification_status", default: "pending", null: false
    t.datetime "certified_at"
    t.bigint "certified_by_id"
    t.decimal "cost_per_1k_input", precision: 12, scale: 6
    t.decimal "cost_per_1k_output", precision: 12, scale: 6
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.bigint "llm_provider_id", null: false
    t.string "model_identifier", null: false
    t.text "revocation_reason"
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["certification_status"], name: "index_llm_models_on_certification_status"
    t.index ["certified_by_id"], name: "index_llm_models_on_certified_by_id"
    t.index ["llm_provider_id", "model_identifier"], name: "index_llm_models_on_llm_provider_id_and_model_identifier", unique: true
    t.index ["llm_provider_id"], name: "index_llm_models_on_llm_provider_id"
  end

  create_table "llm_providers", force: :cascade do |t|
    t.text "api_key"
    t.datetime "api_key_set_at"
    t.bigint "api_key_set_by_id"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_set_by_id"], name: "index_llm_providers_on_api_key_set_by_id"
    t.index ["key"], name: "index_llm_providers_on_key", unique: true
  end

  create_table "mentions", force: :cascade do |t|
    t.integer "char_end"
    t.integer "char_start"
    t.bigint "claim_id", null: false
    t.datetime "created_at", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_mentions_on_claim_id"
  end

  create_table "policies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.text "rationale"
    t.text "statement", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_policies_on_key", unique: true
  end

  create_table "referent_aliases", force: :cascade do |t|
    t.boolean "ambiguous", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "referent_id", null: false
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_referent_aliases_on_name"
    t.index ["referent_id"], name: "index_referent_aliases_on_referent_id"
  end

  create_table "referents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id"
    t.string "key"
    t.string "name", null: false
    t.text "notes"
    t.string "primitive"
    t.string "role"
    t.string "subject"
    t.string "system_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_referents_on_domain_id"
    t.index ["key"], name: "index_referents_on_key", unique: true
    t.index ["name"], name: "index_referents_on_name"
    t.index ["primitive"], name: "index_referents_on_primitive"
    t.index ["system_id"], name: "index_referents_on_system_id", unique: true
  end

  create_table "relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", null: false
    t.text "note"
    t.bigint "source_id", null: false
    t.string "source_type", null: false
    t.bigint "target_id", null: false
    t.string "target_type", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id", "target_type", "target_id", "kind"], name: "index_relationships_on_endpoints_and_kind"
    t.index ["source_type", "source_id"], name: "index_relationships_on_source"
    t.index ["target_type", "target_id"], name: "index_relationships_on_target"
  end

  create_table "term_aliases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "note"
    t.string "source"
    t.bigint "term_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_term_aliases_on_name"
    t.index ["term_id"], name: "index_term_aliases_on_term_id"
  end

  create_table "terms", force: :cascade do |t|
    t.string "canonical_name", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "kind"
    t.text "notes"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_terms_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.bigint "referent_id", null: false
    t.string "role", default: "viewer", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
    t.index ["referent_id"], name: "index_users_on_referent_id"
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "value_probes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.text "notes"
    t.text "prompt", null: false
    t.string "scenario", null: false
    t.datetime "updated_at", null: false
    t.string "value_a", null: false
    t.string "value_b", null: false
    t.index ["key"], name: "index_value_probes_on_key", unique: true
  end

  add_foreign_key "api_tokens", "referents"
  add_foreign_key "api_tokens", "referents", column: "issued_by_id"
  add_foreign_key "assertions", "assertions", column: "supersedes_id"
  add_foreign_key "assertions", "llm_invocations"
  add_foreign_key "assertions", "referents", column: "asserter_id"
  add_foreign_key "claim_categories", "frameworks"
  add_foreign_key "claims", "documents"
  add_foreign_key "delegations", "referents", column: "granted_by_id"
  add_foreign_key "domain_components", "domains"
  add_foreign_key "domain_failure_modes", "domains"
  add_foreign_key "domain_policies", "domains"
  add_foreign_key "domain_policies", "policies"
  add_foreign_key "domains", "frameworks"
  add_foreign_key "evidence_links", "assertions"
  add_foreign_key "evidence_links", "evidence"
  add_foreign_key "flow_stages", "frameworks"
  add_foreign_key "ignored_forms", "referents", column: "decided_by_id"
  add_foreign_key "llm_assignments", "llm_models"
  add_foreign_key "llm_assignments", "referents", column: "created_by_id"
  add_foreign_key "llm_invocations", "llm_assignments"
  add_foreign_key "llm_invocations", "llm_models"
  add_foreign_key "llm_invocations", "referents", column: "agent_id"
  add_foreign_key "llm_models", "llm_providers"
  add_foreign_key "llm_models", "referents", column: "certified_by_id"
  add_foreign_key "llm_providers", "referents", column: "api_key_set_by_id"
  add_foreign_key "mentions", "claims"
  add_foreign_key "referent_aliases", "referents"
  add_foreign_key "referents", "domains"
  add_foreign_key "term_aliases", "terms"
  add_foreign_key "users", "referents"
end
