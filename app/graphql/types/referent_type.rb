module Types
  # Who or what made a claim, and what the system takes it to be.
  class ReferentType < BaseObject
    description "A subject in the graph: a person, a system, or a thing a document names."

    field :id, ID, null: false
    field :key, String, description: "Stable identifier for the system's own actors."
    field :name, String, null: false
    field :subject, String, description: "The Cognitive Passport's Subject — what kind of thing this is."
    field :role, String, description: "The Cognitive Passport's Role — what it is here to do."
    field :primitive, String, null: false, description: "person or system. Only a person's judgement settles a claim."
    field :person, Boolean, null: false, method: :person?

    field :assertions_made, [ AssertionType ], null: false,
          description: "What this referent has asserted. Not what has been asserted about it."

    def assertions_made
      Assertion.where(asserter: object).chronological.limit(200)
    end
  end
end
