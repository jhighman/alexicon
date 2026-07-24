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

ActiveRecord::Schema[8.1].define(version: 2026_07_24_200001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "claim_categories", force: :cascade do |t|
    t.string "confidence_source", null: false
    t.datetime "created_at", null: false
    t.text "definition", null: false
    t.bigint "framework_id", null: false
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
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "position"], name: "index_claims_on_document_id_and_position", unique: true
    t.index ["document_id"], name: "index_claims_on_document_id"
  end

  create_table "classifications", force: :cascade do |t|
    t.bigint "claim_category_id", null: false
    t.bigint "claim_id", null: false
    t.string "classifier"
    t.decimal "confidence", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.boolean "current", default: true, null: false
    t.string "origin", null: false
    t.text "rationale"
    t.datetime "updated_at", null: false
    t.index ["claim_category_id"], name: "index_classifications_on_claim_category_id"
    t.index ["claim_id", "current"], name: "index_classifications_on_claim_id_and_current"
    t.index ["claim_id"], name: "index_classifications_on_claim_id"
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

  create_table "entities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "role"
    t.string "subject"
    t.string "system_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_entities_on_name"
    t.index ["system_id"], name: "index_entities_on_system_id", unique: true
  end

  create_table "entity_aliases", force: :cascade do |t|
    t.boolean "ambiguous", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "entity_id", null: false
    t.string "name", null: false
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_entity_aliases_on_entity_id"
    t.index ["name"], name: "index_entity_aliases_on_name"
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

  create_table "mentions", force: :cascade do |t|
    t.integer "char_end"
    t.integer "char_start"
    t.bigint "claim_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "unresolved", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_mentions_on_claim_id"
    t.index ["status"], name: "index_mentions_on_status"
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

  create_table "resolutions", force: :cascade do |t|
    t.decimal "confidence", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.boolean "current", default: true, null: false
    t.bigint "entity_id", null: false
    t.bigint "mention_id", null: false
    t.string "origin", null: false
    t.text "rationale"
    t.string "resolver"
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_resolutions_on_entity_id"
    t.index ["mention_id", "current"], name: "index_resolutions_on_mention_id_and_current"
    t.index ["mention_id"], name: "index_resolutions_on_mention_id"
  end

  create_table "sentinel_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "disposed_at"
    t.string "disposed_by"
    t.string "disposition", default: "open", null: false
    t.bigint "domain_id"
    t.bigint "flaggable_id", null: false
    t.string "flaggable_type", null: false
    t.text "message", null: false
    t.string "severity", default: "notice", null: false
    t.datetime "updated_at", null: false
    t.index ["disposition"], name: "index_sentinel_flags_on_disposition"
    t.index ["domain_id"], name: "index_sentinel_flags_on_domain_id"
    t.index ["flaggable_type", "flaggable_id"], name: "index_sentinel_flags_on_subject"
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

  create_table "transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.bigint "from_claim_id", null: false
    t.text "note"
    t.decimal "score", precision: 5, scale: 4
    t.bigint "to_claim_id", null: false
    t.datetime "updated_at", null: false
    t.string "verdict", default: "undetermined", null: false
    t.index ["document_id"], name: "index_transitions_on_document_id"
    t.index ["from_claim_id", "to_claim_id"], name: "index_transitions_on_from_claim_id_and_to_claim_id", unique: true
    t.index ["from_claim_id"], name: "index_transitions_on_from_claim_id"
    t.index ["to_claim_id"], name: "index_transitions_on_to_claim_id"
  end

  add_foreign_key "claim_categories", "frameworks"
  add_foreign_key "claims", "documents"
  add_foreign_key "classifications", "claim_categories"
  add_foreign_key "classifications", "claims"
  add_foreign_key "domain_components", "domains"
  add_foreign_key "domain_failure_modes", "domains"
  add_foreign_key "domain_policies", "domains"
  add_foreign_key "domain_policies", "policies"
  add_foreign_key "domains", "frameworks"
  add_foreign_key "entity_aliases", "entities"
  add_foreign_key "flow_stages", "frameworks"
  add_foreign_key "mentions", "claims"
  add_foreign_key "resolutions", "entities"
  add_foreign_key "resolutions", "mentions"
  add_foreign_key "sentinel_flags", "domains"
  add_foreign_key "term_aliases", "terms"
  add_foreign_key "transitions", "claims", column: "from_claim_id"
  add_foreign_key "transitions", "claims", column: "to_claim_id"
  add_foreign_key "transitions", "documents"
end
