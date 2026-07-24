class DocumentsController < ApplicationController
  def index
    @documents = Document.order(created_at: :desc).limit(50)
  end

  def new
    @document = Document.new
  end

  def create
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
    @claims = @document.claims.includes(:mentions)
    @transitions = @document.transitions.includes(:source, :target)
    @open_flags = @document.flags.includes(:asserter, :subject).select(&:open?)
    @history = Assertion.where(id: @document.flags.select(:id))
                        .or(Assertion.where(subject_type: "Claim", subject_id: @claims.select(:id)))
                        .includes(:asserter, :subject)
                        .chronological
  end

  private

  def ingest_notice(result)
    parts = [ "#{result.claims.count} claims", "#{result.mentions.count} mentions" ]
    parts << "#{result.document.open_stops.count} identity STOPs" if result.blocked?
    "Ingested: #{parts.join(', ')}."
  end
end
