# One claim at a time, with no indication of what the machine made of it.
#
# The controller never loads a classification into the view. `BlindReading`
# refuses to hand one over for an unanswered claim, so a template cannot leak
# what it cannot obtain — the blindness is structural rather than a matter of
# remembering not to render something.
class BlindReadingsController < ApplicationController
  before_action :load_reading

  def show
    @claim = @reading.next_claim
    return redirect_to comparison_document_blind_reading_path(@document) if @claim.nil?

    @context = @reading.context_for(@claim)
    @categories = Framework.current!.claim_categories
  end

  def create
    claim = @document.claims.substantive.find(params[:claim_id])

    if params[:abstain].present?
      @reading.abstain!(claim, rationale: params[:rationale])
    else
      category = Framework.current!.claim_categories.find_by(id: params[:claim_category_id])
      return redirect_to document_blind_reading_path(@document), alert: PICK unless category

      @reading.record!(claim, category: category, rationale: params[:rationale],
                              unsure: params[:unsure] == "1")
    end

    redirect_to document_blind_reading_path(@document)
  end

  # The reveal. Only claims this reader has already answered appear, so reaching
  # this page early shows less rather than showing the answers.
  def comparison
    @comparison = @reading.comparison
  end

  private

  PICK = "Pick a category, or say you cannot tell.".freeze

  def load_reading
    @document = Document.find(params[:document_id])
    authorize @document, :type_claims?
    @reading = BlindReading.new(@document, reader: current_reviewer)
  end
end
