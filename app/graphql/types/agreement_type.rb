module Types
  # A single reading is a sample; this is what says which you are looking at.
  class AgreementType < BaseObject
    description "What repeated readings of a claim agreed on, and on how many readings."

    field :category, ClaimCategoryType, description: "Null when the readings reached no majority."
    field :agreeing, Integer, null: false
    field :readings, Integer, null: false
    field :decided, Boolean, null: false, method: :decided?
    field :unanimous, Boolean, null: false, method: :unanimous?
    field :single, Boolean, null: false, method: :single?,
          description: "One reading. Measured at 87.9% reproducible, so a sample rather than a finding."
    field :rate, Float
    field :description, String, null: false, description: '"2 of 3" — says more than a percentage.'

    def description = object.to_s
  end
end
