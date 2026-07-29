module Types
  class ClaimType < BaseObject
    description "One individually classifiable statement within a document."

    field :id, ID, null: false
    field :position, Integer, null: false
    field :text, String, null: false
    field :structural, Boolean, null: false,
          description: "A heading, a table row, a lead-in. Part of the document, not a claim about anything."

    field :category, ClaimCategoryType,
          description: "DERIVED, never stored. A person's reading settles it; otherwise a strict " \
                       "majority of the classifier's readings."
    field :agreement, AgreementType, null: false
    field :machine_agreement, AgreementType, null: false,
          description: "What the classification pass alone concluded, ignoring people and blind readings."

    field :classifications, [ AssertionType ], null: false,
          description: "Every reading, kept. Disagreement survives in the record."
    field :outgoing_transitions, [ TransitionType ], null: false
    field :incoming_transitions, [ TransitionType ], null: false

    def classifications = object.classifications.includes(:asserter, :object)
  end
end
