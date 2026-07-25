# What it costs to move from one kind of claim to another.
#
# `justification_rank` gave three values to four categories, so
# "objective -> interpretive" and "interpretive -> ontological" both measured as
# +1. They are not the same move: the first assigns meaning to a fact, the
# second converts meaning into a claim about what exists. The audit that reads
# distance could therefore not see the transition the framework is named for.
#
# The weight is per ORDERED PAIR because the asymmetry is the point. Going from
# ontological back to observation is not a promotion at all.
class CreateCategoryPromotions < ActiveRecord::Migration[8.1]
  def change
    create_table :category_promotions do |t|
      t.references :framework, null: false, foreign_key: true
      t.references :from_category, null: false, foreign_key: { to_table: :claim_categories }
      t.references :to_category, null: false, foreign_key: { to_table: :claim_categories }
      t.integer :weight, null: false, default: 0
      t.text :rationale
      t.timestamps

      t.index %i[framework_id from_category_id to_category_id], unique: true,
              name: "index_category_promotions_on_pair"
    end
  end
end
