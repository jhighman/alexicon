module Types
  # A measurement OF the system, recorded as an assertion about the model like
  # any other claim, and readable only by someone who may see the model registry.
  class BaselineMeasurementType < BaseObject
    description "One recorded figure about the model this system runs on."

    field :version, String, null: false
    field :criterion, String, null: false
    field :rate, Float
    field :measured, GraphQL::Types::JSON, null: false
    field :sample, GraphQL::Types::JSON, null: false
    field :conditions, GraphQL::Types::JSON, null: false,
          description: "What the figure was taken under. Baseline.compare refuses a pair whose " \
                       "conditions differ rather than reporting a difference that may be the instrument."
    field :caveats, [ String ], description: "What the figure cannot support. Not decoration."
    field :detail, GraphQL::Types::JSON
    field :code_sha, String
    field :recorded_at, GraphQL::Types::ISO8601DateTime, null: false
    field :model_identifier, String, null: false

    def version = object.assertion.claim["baseline"]
    def code_sha = object.assertion.claim.dig("code", "sha")
    def model_identifier = object.model.model_identifier
  end
end
