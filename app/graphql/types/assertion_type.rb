module Types
  # The one record type. Everything in this system is an assertion, including
  # assertions about assertions — which is the recursion REST cannot walk in one
  # request and the reason this layer exists.
  class AssertionType < BaseObject
    description "An accountable claim by someone, about something. The only record type there is."

    field :id, ID, null: false
    field :act, String, null: false, description: "assert, classify, flag, accept, reject, resolve, …"
    field :asserted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :asserter, ReferentType, null: false, description: "Attribution is to a Referent, never to an account."
    field :human, Boolean, null: false, method: :human?
    field :blind, Boolean, null: false, method: :blind?,
          description: "Taken without sight of any other reading. Recorded in full, counted in no tally."

    field :claim, GraphQL::Types::JSON, description: "The payload: confidence, rationale, verdict, measurement."
    field :severity, String, description: "notice, concern or stop, for a flag."

    field :subject_type, String, null: false, description: "What this assertion is ABOUT."
    field :subject_id, ID, null: false
    field :subject_label, String, description: "The subject in one line, whatever kind it is."

    field :object_type, String, description: "What it points AT, when it points at anything."
    field :category, ClaimCategoryType, description: "The category, when this assertion is a classification."

    field :supersedes, AssertionType, description: "The assertion this one replaces. Nothing is overwritten."
    field :standing, Boolean, null: false, description: "Whether anything has superseded it."

    field :assertions, [ AssertionType ], null: false,
          description: "Assertions made ABOUT this one — challenges, corroborations, dispositions. " \
                       "This is what makes the record recursive, and why the schema caps depth."

    def category = object.object.is_a?(ClaimCategory) ? object.object : nil
    def object_type = object.object_type
    def standing = object.superseded_by.empty?
    def assertions = object.assertions.chronological

    def subject_label
      subject = object.subject
      return subject.text.to_s.truncate(120) if subject.respond_to?(:text)
      return subject.name if subject.respond_to?(:name)

      "#{object.subject_type} #{object.subject_id}"
    end
  end
end
