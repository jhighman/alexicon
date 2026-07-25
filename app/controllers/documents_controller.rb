class DocumentsController < ApplicationController
  def index
    authorize Document, :index?
    @documents = policy_scope(Document).order(created_at: :desc).limit(50)
  end

  def new
    @document = Document.new
    authorize @document
  end

  def create
    authorize Document
    attrs = params.require(:document).permit(:title, :body)

    if attrs[:body].to_s.strip.blank?
      @document = Document.new(attrs)
      flash.now[:alert] = "Paste some text to review."
      return render :new, status: :unprocessable_content
    end

    result = DocumentIngest.ingest!(body: attrs[:body], title: attrs[:title].presence)
    redirect_to result.document, notice: ingest_notice(result)
  rescue ActiveRecord::RecordInvalid => e
    @document = Document.new(attrs)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_content
  end

  def show
    @document = Document.find(params[:id])
    authorize @document
    @claims = @document.claims.includes(:mentions)
    @transitions = @document.transitions.includes(:source, :target)
    open_flags = @document.flags.includes(:asserter, :subject).select(&:open?)

    # One question per name, not per occurrence. An essay naming Polanyi three
    # times raised three identical STOPs; answering the name answers all of them.
    identity, @open_flags = open_flags.partition { it.subject.is_a?(Mention) }
    @identity_groups = identity.group_by { it.subject.text }
                               .sort_by { |name, flags| [ -flags.size, name ] }
    @history = Assertion.where(id: @document.flags.select(:id))
                        .or(Assertion.where(subject_type: "Claim", subject_id: @claims.select(:id)))
                        .includes(:asserter, :subject)
                        .chronological
  end

  def classify
    document = Document.find(params[:id])
    authorize document, :classify?

    readiness = ClaimClassifier.readiness
    return redirect_back_to(document, alert: "Cannot classify: #{readiness.problem}.") unless readiness.ready?

    ClassifyDocumentJob.perform_later(document)
    redirect_to document,
                notice: "Classifying #{helpers.pluralize(document.unclassified_claims_count, 'claim')}. " \
                        "Refresh in a moment."
  end

  # Asks the model what the unfamiliar names refer to. It proposes; a person
  # still accepts. Nothing here lifts a STOP.
  def propose_identities
    document = Document.find(params[:id])
    authorize document, :classify?

    ProposeIdentitiesJob.perform_later(document)
    redirect_to document,
                notice: "Asking about #{helpers.pluralize(document.unresolved_name_count, 'name')}. " \
                        "You will still be the one to accept."
  end

  def govern
    document = Document.find(params[:id])
    authorize document, :govern?

    return redirect_back_to(document, alert: LOCKED) unless document.executable?

    GovernDocumentJob.perform_later(document)
    redirect_to document, notice: "Judging the steps between claims. Refresh in a moment."
  end

  private

  LOCKED = "Identity has to be established first — answer the open STOPs.".freeze

  def redirect_back_to(document, alert:)
    redirect_to document, alert: alert
  end

  def ingest_notice(result)
    parts = [ "#{result.claims.count} claims", "#{result.mentions.count} mentions" ]
    parts << "#{result.document.open_stops.count} identity STOPs" if result.blocked?
    "Ingested: #{parts.join(', ')}."
  end
end
