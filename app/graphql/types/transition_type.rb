module Types
  # The unit of governance: the step BETWEEN two claims. Claims are typed; steps
  # are judged.
  class TransitionType < BaseObject
    description "A step from one claim to the next, and whether it was earned."

    field :id, ID, null: false
    field :source, ClaimType, null: false
    field :target, ClaimType, null: false
    field :verdict, String, null: false,
          description: "DERIVED. earned, unearned, or undetermined when either end is untyped."
    field :category_change, Boolean, null: false, method: :category_change?
    field :judgements, [ AssertionType ], null: false,
          description: "The Sentinel's rulings on this step."

    def verdict = object.verdict.to_s
    def judgements = object.assertions.chronological
  end
end
