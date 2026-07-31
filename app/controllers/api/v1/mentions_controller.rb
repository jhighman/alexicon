# Answering an identity STOP programmatically.
#
# Both acts are judgements, so both pass the delegation gate. An agent with no
# delegation may see the question and not answer it — which is the posture the
# system starts in.
class Api::V1::MentionsController < Api::V1::BaseController
  def index
    authorize Mention
    document = Document.find(params[:document_id])
    render json: { document_id: document.id, names: unresolved_names(document) }
  end

  def ground
    mention = Mention.find(params[:id])
    authorize mention, :ground?
    require_delegation!("ground_mention")

    # `person` is explicit and defaults to false: personhood allocates
    # authority and is never inferred from the subject string (ADR 22).
    result = GroundMention.call(mention, by: current_reviewer,
                                         subject: params[:subject], role: params[:role],
                                         same_as: params[:same_as_id].presence,
                                         person: ActiveModel::Type::Boolean.new.cast(params[:person]) || false)

    render json: { grounded: result.referent.name, passport: result.referent.passport,
                   status: result.mention.status, occurrences: result.occurrences,
                   decided_by: current_reviewer.name, inferred: !current_token.human? }
  rescue GroundMention::IncompletePassport
    unprocessable("a passport needs both subject and role, or a same_as_id")
  rescue ActiveRecord::RecordInvalid => e
    unprocessable(e.message)
  end

  def ignore
    mention = Mention.find(params[:id])
    authorize mention, :ignore?
    require_delegation!("ignore_mention")

    result = IgnoreMention.call(mention, by: current_reviewer)

    render json: { form: result.form, cleared: result.occurrences,
                   decided_by: current_reviewer.name, inferred: !current_token.human? }
  end

  private

  # One entry per name, with whatever the proposer suggested, so an agent can
  # answer the question rather than reconstruct it.
  def unresolved_names(document)
    document.open_stops.select { it.subject.is_a?(Mention) }.group_by { it.subject.text }
            .map do |text, flags|
      mention = flags.first.subject
      proposal = mention.identity_proposal
      { name: text, mention_id: mention.id, occurrences: flags.size,
        proposal: proposal && { kind: proposal.claim["proposal"], subject: proposal.claim["subject"],
                                role: proposal.claim["role"], same_as: proposal.claim["same_as"],
                                confidence: proposal.confidence, rationale: proposal.rationale,
                                by: proposal.asserter.name } }
    end
  end
end
