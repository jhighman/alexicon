module Types
  class DocumentType < BaseObject
    description "A text under analysis."

    field :id, ID, null: false
    field :title, String
    field :body, String, description: "The source, never modified. Every claim traces to a span of it."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :claims, [ ClaimType ], null: false do
      argument :substantive, Boolean, required: false,
               description: "Exclude structure — headings, table rows, lead-ins."
    end
    field :claim_count, Integer, null: false
    field :transitions, [ TransitionType ], null: false
    field :executable, Boolean, null: false, method: :executable?,
          description: "False while any identity STOP is open. The lock guards predication, not description."
    field :open_stops, [ AssertionType ], null: false,
          description: "Questions waiting on a person. Nothing may be predicated of an unresolved name."

    def claims(substantive: false)
      scope = substantive ? object.claims.substantive : object.claims
      scope.order(:position).includes(:assertions)
    end

    def claim_count = object.claims.count
    def transitions = object.transitions.includes(:source, :target)
  end
end
