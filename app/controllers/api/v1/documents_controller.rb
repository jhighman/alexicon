# Submitting a text, and running the analyses over it.
#
# These queue work rather than doing it: classification is minutes of API calls,
# and a request that blocks for minutes is a request that times out. The
# response says what was accepted, and the document reports its own state.
class Api::V1::DocumentsController < Api::V1::BaseController
  def index
    authorize Document
    render json: { documents: policy_scope(Document).order(created_at: :desc).map { summary(it) } }
  end

  def show
    document = Document.find(params[:id])
    authorize document
    render json: detail(document)
  end

  def create
    authorize Document
    body = params.require(:document).require(:body)

    result = DocumentIngest.ingest!(body: body, title: params[:document][:title])
    render json: detail(result.document).merge(
      ingested: { claims: result.claims.size, mentions: result.mentions.size,
                  transitions: result.transitions.size, blocked: result.blocked? }
    ), status: :created
  end

  def classify
    document = Document.find(params[:id])
    authorize document, :classify?

    readiness = ClaimClassifier.readiness
    return unprocessable("cannot classify: #{readiness.problem}") unless readiness.ready?

    ClassifyDocumentJob.perform_later(document)
    render json: { queued: "classify", document_id: document.id,
                   model: readiness.model.display_name,
                   unclassified: document.unclassified_claims_count }, status: :accepted
  end

  def propose_identities
    document = Document.find(params[:id])
    authorize document, :classify?

    ProposeIdentitiesJob.perform_later(document)
    render json: { queued: "propose_identities", document_id: document.id,
                   names: document.unresolved_name_count,
                   note: "Proposals only. A STOP lifts when someone accepts." }, status: :accepted
  end

  def govern
    document = Document.find(params[:id])
    authorize document, :govern?

    unless document.executable?
      return unprocessable("identity is unresolved: #{document.unresolved_name_count} name(s) " \
                           "must be answered before a step can be judged")
    end

    GovernDocumentJob.perform_later(document)
    render json: { queued: "govern", document_id: document.id,
                   steps: document.transitions.count }, status: :accepted
  end

  private

  def summary(document)
    { id: document.id, title: document.title, claims: document.claims.count,
      executable: document.executable?, created_at: document.created_at }
  end

  def detail(document)
    steps = document.transitions
    summary(document).merge(
      substantive_claims: document.claims.substantive.count,
      structural_claims: document.claims.count(&:structural?),
      classified: document.classified_claims_count,
      open_stops: document.open_stops.count,
      unresolved_names: document.unresolved_name_count,
      steps: { total: steps.count,
               judged: steps.count { it.verdict != "undetermined" },
               unearned: steps.count(&:unearned?) }
    )
  end
end
