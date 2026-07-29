module Types
  class QueryType < BaseObject
    description "Reading the assertion graph. There are no mutations — see below."

    field :document, DocumentType do
      argument :id, ID
    end

    field :documents, [ DocumentType ], null: false do
      argument :limit, Integer, required: false
    end

    field :claim, ClaimType do
      argument :id, ID
    end

    field :assertion, AssertionType,
          description: "Any assertion, including one about another assertion." do
      argument :id, ID
    end

    field :referent, ReferentType do
      argument :key, String, required: false
      argument :id, ID, required: false
    end

    field :referents, [ ReferentType ], null: false do
      argument :primitive, String, required: false, description: "person or system."
    end

    field :categories, [ ClaimCategoryType ], null: false,
          description: "The current framework's kinds of claim."

    field :values, [ FrameworkValueType ], null: false,
          description: "The vocabulary of commitments a step or a response can put first."

    field :baseline_versions, [ String ], null: false
    field :baseline, [ BaselineMeasurementType ], null: false,
          description: "Requires a role that may see the model registry." do
      argument :version, String
    end

    def document(id:) = Document.find_by(id: id)
    def documents(limit: 25) = Document.order(created_at: :desc).limit([ limit, 100 ].min)
    def claim(id:) = Claim.find_by(id: id)
    def assertion(id:) = Assertion.find_by(id: id)
    def categories = Framework.current!.claim_categories
    def values = FrameworkValue.vocabulary

    def referent(key: nil, id: nil)
      return Referent.find_by(key: key) if key.present?

      Referent.find_by(id: id)
    end

    def referents(primitive: nil)
      primitive.present? ? Referent.where(primitive: primitive).order(:name) : Referent.order(:name)
    end

    def baseline_versions = Baseline.versions

    # The one place a capability question is asked inside the schema. Everything
    # else here is what a viewer may already read through the browser; a
    # measurement about the model is not.
    def baseline(version:)
      unless context[:token]&.can_view_llm_registry?
        raise GraphQL::ExecutionError, "This token's role does not allow reading the model registry."
      end

      Baseline.for(version: version)
    end
  end
end
