# Vouching for a model, and withdrawing that.
#
# Certification is the narrowest capability in the system: it decides which
# model may influence any judgement at all. Delegating it to an agent is
# possible and deliberately not the default — an agent certifying the model
# that will then answer for it is a loop with nobody in it.
class Api::V1::LlmModelsController < Api::V1::BaseController
  def index
    authorize LlmModel
    render json: { models: policy_scope(LlmModel).includes(:llm_provider).map { serialise(it) } }
  end

  def certify
    model = LlmModel.find(params[:id])
    authorize model, :certify?
    require_delegation!("certify_model")

    model.certify!(current_reviewer)
    render json: serialise(model.reload).merge(inferred: !current_token.human?)
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    unprocessable(e.message)
  end

  def revoke
    model = LlmModel.find(params[:id])
    authorize model, :revoke?
    require_delegation!("revoke_model")

    model.revoke!(reason: params[:reason].presence || "Revoked via API.", by: current_reviewer)
    render json: serialise(model.reload).merge(inferred: !current_token.human?)
  end

  private

  def serialise(model)
    { id: model.id, model_identifier: model.model_identifier, display_name: model.display_name,
      provider: model.llm_provider.key, status: model.certification_status,
      invocable: model.invocable?, certified_by: model.certified_by&.name }
  end
end
