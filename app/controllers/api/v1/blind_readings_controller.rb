# Typing claims, for something that is not a person.
#
# This is the act the whole programmatic surface was built for: a review
# decision the application expects a human to make, made by an agent instead, on
# the record, as itself. What comes back is a second judge — and nine of the ten
# figures in the baseline are the system checking itself, so a second judge is
# the first thing here that is not.
#
# It is not a correctness measurement and must never be recorded as one. Two
# models agreeing tells you they agree.
class Api::V1::BlindReadingsController < Api::V1::BaseController
  before_action :load_reading

  # No delegation required. The point of this endpoint is that it tells you
  # nothing about what anyone else concluded, so reading it decides nothing.
  def show
    claim = @reading.next_claim
    return render json: progress.merge(claim: nil) if claim.nil?

    render json: progress.merge(
      claim: { id: claim.id, position: claim.position, text: claim.text },
      context: @reading.context_for(claim).map(&:text),
      categories: Framework.current!.claim_categories.map { category_json(it) }
    )
  end

  def create
    require_delegation!("type_claim")
    claim = @document.claims.substantive.find(params.require(:claim_id))

    if params[:abstain].present?
      @reading.abstain!(claim, rationale: params[:rationale])
      return render json: recorded(claim, nil)
    end

    category = Framework.current!.claim_categories.find_by(key: params[:category].to_s.strip)
    return unprocessable(pick_one) if category.nil?

    @reading.record!(claim, category: category, rationale: params[:rationale],
                            unsure: params[:unsure].to_s == "true")
    render json: recorded(claim, category), status: :created
  end

  # Only claims this reader has answered. Asking early returns less rather than
  # returning the answers.
  def comparison
    c = @reading.comparison

    render json: {
      document: @document.id,
      typed: c.pairs.size,
      agreement: { rate: c.rate, agreed: c.agreed, compared: c.both_typed.size },
      only_you: c.human_only, only_classifier: c.machine_only, neither: c.both_abstained,
      sure_disagreements: c.confident_disagreements.size,
      moves: c.moves,
      disagreements: c.disagreed.map { disagreement_json(it) },
      note: "Rate is over claims both judges typed. A claim one side abstained on " \
            "is not a disagreement about its category. This measures agreement " \
            "between two judges, which is not correctness."
    }
  end

  private

  def load_reading
    @document = Document.find(params[:document_id])
    authorize @document, :type_claims?
    @reading = BlindReading.new(@document, reader: current_reviewer)
  end

  def progress
    { document: @document.id, typed: @reading.answered_count,
      total: @reading.total, complete: @reading.complete? }
  end

  def category_json(category)
    { key: category.key, name: category.name, definition: category.definition }
  end

  def recorded(claim, category)
    {
      recorded: true, claim: claim.id, category: category&.key,
      abstained: category.nil?, blind: true, decided_by: current_reviewer.name,
      # An agent's blind reading is a second opinion, not a further vote in the
      # classifier's tally. It is recorded in full and moves nothing.
      counts_toward_classification: current_token.human?
    }
  end

  def disagreement_json(pair)
    { claim: pair.claim.id, text: pair.claim.text, yours: pair.human.key,
      classifier: pair.machine.key, unsure: pair.unsure,
      classifier_agreement: pair.machine_agreement.to_s }
  end

  def pick_one
    keys = Framework.current!.claim_categories.map(&:key)
    "Name a category (#{keys.join(', ')}), or send abstain=true to say you cannot tell."
  end
end
