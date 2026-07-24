# The fifth primitive, and the mechanism by which anything enters the graph.
#
# A Relationship is not metadata attached to two referents. It is an
# independently governable object with its own lifecycle, authority, and
# evidentiary requirements. "Sarah works for Acme" cannot be reduced to Sarah
# or to Acme, yet ceases to exist if either endpoint is removed.
#
# Deliberately, `relationships` carries NO status column. Status is derived
# from the assertions that concern it. Storing current state would rebuild the
# mutable-state model the Assertion Principle exists to replace.
class CreateRelationshipsAndAssertions < ActiveRecord::Migration[8.1]
  def change
    create_table :relationships do |t|
      t.references :source_referent, null: false, foreign_key: { to_table: :referents }
      t.references :target_referent, null: false, foreign_key: { to_table: :referents }
      t.string :kind, null: false                # employment, licence, accreditation, ...
      t.text   :description
      t.timestamps
    end
    add_index :relationships, [ :source_referent_id, :target_referent_id, :kind ],
              name: "index_relationships_on_endpoints_and_kind"

    # Evidence supports an assertion without being identical to it. One
    # document may support many assertions; one assertion may rest on many
    # forms of evidence. Hence a join rather than a column.
    # kind: document | observation | measurement | prior_assertion |
    #       process | cryptographic_proof
    create_table :evidence do |t|
      t.string   :kind, null: false
      t.string   :reference                      # locator: URI, doc number, hash
      t.text     :description
      t.datetime :obtained_at
      t.timestamps
    end
    add_index :evidence, :kind

    # An assertion is an EVENT, not a property. It records that a claim was
    # made -- never that the claim was correct. Immutability is enforced in the
    # model: an error is answered by a later assertion, never overwritten.
    create_table :assertions do |t|
      # Every assertion has an accountable asserter. Accountability begins
      # with attribution.
      t.references :asserter, null: false, foreign_key: { to_table: :referents }

      # The subject may be a relationship, a referent, or a prior assertion.
      # Assertions are therefore recursive: claims may support, amend, revoke
      # or challenge one another.
      t.references :subject, polymorphic: true, null: false

      # assert | amend | revoke | challenge | delegate
      t.string :act, null: false, default: "assert"

      # The proposed state of the world -- not the world's condition.
      t.jsonb :claim, null: false, default: {}

      # Time is structural, not metadata. When the claim was made, and the
      # window over which it purports to hold.
      t.datetime :asserted_at, null: false
      t.datetime :valid_from
      t.datetime :valid_until

      t.text :provenance                          # signature, authority, governing process

      # Supersession points FORWARD from the new assertion to the old one. The
      # prior assertion is never touched.
      t.references :supersedes, foreign_key: { to_table: :assertions }

      t.timestamps
    end
    add_index :assertions, [ :subject_type, :subject_id, :asserted_at ]
    add_index :assertions, :act

    create_table :evidence_links do |t|
      t.references :assertion, null: false, foreign_key: true
      t.references :evidence,  null: false, foreign_key: true
      t.text :note                                # how this evidence bears on the claim
      t.timestamps
    end
    add_index :evidence_links, [ :assertion_id, :evidence_id ], unique: true
  end
end
