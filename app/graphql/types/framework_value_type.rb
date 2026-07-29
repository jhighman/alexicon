module Types
  class FrameworkValueType < BaseObject
    description "A commitment a step, or a response, can put first."

    field :key, String, null: false
    field :name, String, null: false
    field :definition, String, null: false
    field :subordinates, String, null: false,
          description: "What putting this first sets aside. A value with nothing to " \
                       "subordinate is a preference rather than a commitment."
    field :provenance, String, null: false,
          description: "probe — already in the record as a value a model was tested " \
                       "against. proposed — intuition, and marked as such."
    field :established, Boolean, null: false, method: :established?
    field :domain, String, null: false

    def domain = object.domain.name
  end
end
