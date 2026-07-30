# Reviewing a judgement. The counterpart to blind typing, and not the same
# surface: this one shows the system's conclusion, so nothing recorded through
# it can serve as a measurement of whether the system was right.
#
# It never serves a claim classification. Claims are typed blind or not at all.
class Api::V1::ReviewsController < Api::V1::BaseController
  before_action :load_review

  def show
    item = @review.next_item
    return render json: progress.merge(item: nil) if item.nil?

    render json: progress.merge(item: {
      id: item.id, kind: item.kind, question: item.question,
      detail: item.detail, context: item.context, caveat: item.caveat
    })
  end

  def create
    require_delegation!("dispose_flag")
    assertion = Assertion.find(params.require(:id))

    disposal = @review.dispose!(assertion, verdict: params.require(:verdict),
                                           rationale: params[:rationale])

    render json: { reviewed: assertion.id, verdict: disposal.act,
                   decided_by: current_reviewer.name, inferred: !current_token.human? },
           status: :created
  rescue Review::UnknownVerdict, Review::NotReviewable => e
    unprocessable(e.message)
  end

  private

  def load_review
    @document = Document.find(params[:document_id])
    authorize @document, :classify?
    @review = Review.new(@document, reviewer: current_reviewer)
  end

  def progress
    { document: @document.id, reviewed: @review.reviewed_count, total: @review.total }
  end
end
