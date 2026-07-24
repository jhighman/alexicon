# The registry, and the act of vouching for a model.
class LlmModelsController < ApplicationController
  def index
    authorize LlmModel
    @models = policy_scope(LlmModel).includes(:llm_provider, :certified_by).order(:display_name)
    @assignments = LlmAssignment.includes(:llm_model).order(:agent_pattern)
  end

  def certify
    model = LlmModel.find(params[:id])
    authorize model, :certify?

    model.certify!(current_reviewer)
    redirect_to llm_models_path,
                notice: "#{model.display_name} certified by #{current_reviewer.name}."
  rescue ArgumentError => e
    redirect_to llm_models_path, alert: e.message
  end

  def revoke
    model = LlmModel.find(params[:id])
    authorize model, :revoke?

    model.revoke!(reason: params[:reason].presence || "Revoked from the registry.",
                  by: current_reviewer)
    redirect_to llm_models_path, alert: "#{model.display_name} revoked. It can no longer be used."
  end
end
