# The working layer: documents in, claims out, transitions between them.
#
# Classification is kept in its own table rather than as a column on claims.
# The framework's own axiom -- inference must not become evidence -- applies
# to this system's output too: a machine judgement is recorded AS a judgement,
# with its origin, and a human disposition never overwrites it.
class CreateAnalysis < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.text   :body, null: false
      t.string :source_kind                            # pasted, uploaded, composed
      t.timestamps
    end

    create_table :claims do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :position,   null: false
      t.text    :text,       null: false
      t.integer :char_start
      t.integer :char_end
      t.timestamps
    end
    add_index :claims, [ :document_id, :position ], unique: true

    create_table :classifications do |t|
      t.references :claim,           null: false, foreign_key: true
      t.references :claim_category,  null: false, foreign_key: true
      t.string  :origin,     null: false             # model | human
      t.string  :classifier                          # model id, or user
      t.decimal :confidence, precision: 5, scale: 4
      t.text    :rationale
      t.boolean :current, null: false, default: true
      t.timestamps
    end
    add_index :classifications, [ :claim_id, :current ]

    # The transition is the unit of risk, not the claim.
    create_table :transitions do |t|
      t.references :document,  null: false, foreign_key: true
      t.references :from_claim, null: false, foreign_key: { to_table: :claims }
      t.references :to_claim,   null: false, foreign_key: { to_table: :claims }
      t.string  :verdict, null: false, default: "undetermined" # earned | unearned | undetermined
      t.decimal :score, precision: 5, scale: 4
      t.text    :note
      t.timestamps
    end
    add_index :transitions, [ :from_claim_id, :to_claim_id ], unique: true

    # A flag never asserts truth. It asserts that a category changed without a
    # corresponding increase in justification.
    create_table :sentinel_flags do |t|
      t.references :transition, null: false, foreign_key: true
      t.references :domain,     foreign_key: true      # which domain raised it
      t.string  :severity,    null: false, default: "notice"
      t.text    :message,     null: false
      t.string  :disposition, null: false, default: "open" # open | accepted | rejected
      t.string  :disposed_by
      t.datetime :disposed_at
      t.timestamps
    end
    add_index :sentinel_flags, :disposition
  end
end
