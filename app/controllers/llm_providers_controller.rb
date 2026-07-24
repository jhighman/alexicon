# Registering a provider is bookkeeping; whether it can be CALLED is not.
# A provider without an adapter is listable, and its models cannot be
# certified — see LlmModel#provider_must_be_invocable_to_certify.
class LlmProvidersController < ApplicationController
  def index
    authorize LlmProvider
    @providers = policy_scope(LlmProvider).includes(:llm_models).order(:name)
  end

  def new
    @provider = LlmProvider.new
    authorize @provider
  end

  def create
    @provider = LlmProvider.new(provider_params)
    authorize @provider

    if @provider.save
      redirect_to llm_providers_path, notice: "#{@provider.name} registered."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @provider = LlmProvider.find(params[:id])
    authorize @provider
  end

  def update
    @provider = LlmProvider.find(params[:id])
    authorize @provider

    if @provider.update(provider_params)
      redirect_to llm_providers_path, notice: "#{@provider.name} updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def provider_params = params.require(:llm_provider).permit(:key, :name, :status, :notes)
end
