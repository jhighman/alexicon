# The registry, and the act of vouching for a model.
#
# Registering a model is bookkeeping. Certifying it is a judgement, and it
# fails if the provider has no adapter — vouching for something the code
# cannot call would claim a capability this application does not have.
class LlmModelsController < ApplicationController
  def index
    authorize LlmModel
    @models = policy_scope(LlmModel).includes(:llm_provider, :certified_by).order(:display_name)
    @providers = LlmProvider.order(:name)
    @assignments = LlmAssignment.includes(llm_model: :llm_provider).order(:agent_pattern)
    @assignment = LlmAssignment.new
  end

  def new
    @model = LlmModel.new(llm_provider_id: params[:llm_provider_id])
    authorize @model
    @providers = LlmProvider.order(:name)
  end

  def create
    @model = LlmModel.new(model_params)
    authorize @model

    if @model.save
      redirect_to llm_models_path,
                  notice: "#{@model.display_name} registered. Nothing routes to it until it is certified."
    else
      @providers = LlmProvider.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def certify
    model = LlmModel.find(params[:id])
    authorize model, :certify?

    model.certify!(current_reviewer)
    redirect_to llm_models_path, notice: "#{model.display_name} certified by #{current_reviewer.name}."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to llm_models_path, alert: e.message
  end

  def revoke
    model = LlmModel.find(params[:id])
    authorize model, :revoke?

    model.revoke!(reason: params[:reason].presence || "Revoked from the registry.",
                  by: current_reviewer)
    redirect_to llm_models_path, alert: "#{model.display_name} revoked. It can no longer be used."
  end

  private

  def model_params
    params.require(:llm_model).permit(:llm_provider_id, :model_identifier, :display_name,
                                      :cost_per_1k_input, :cost_per_1k_output)
  end
end
