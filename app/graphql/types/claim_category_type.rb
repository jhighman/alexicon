module Types
  class ClaimCategoryType < BaseObject
    description "One of the framework's kinds of claim. They differ in KIND, never in rank."

    field :key, String, null: false
    field :name, String, null: false
    field :definition, String, null: false
    field :confidence_source, String, null: false, description: "What a claim of this kind rests on."
    field :justification_rank, Integer,
          description: "How much warrant a claim of this kind needs. NOT precedence, and not " \
                       "what a move between two kinds costs — see CategoryPromotion for that."
  end
end
