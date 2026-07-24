# Registering a provider is bookkeeping; whether it can be CALLED is not.
# A provider without an adapter is listable, and its models cannot be
# certified — see LlmModel#provider_must_be_invocable_to_certify.
#
# The API key is handled apart from the other attributes because it is
# write-only: it is never rendered back, a blank field means "leave it alone"
# rather than "erase it", and clearing it is its own deliberate act.
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
      apply_api_key
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
      apply_api_key
      redirect_to llm_providers_path, notice: "#{@provider.name} updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Falls back to the environment variable, if one is set there.
  def clear_credential
    @provider = LlmProvider.find(params[:id])
    authorize @provider, :update?

    @provider.clear_api_key!
    redirect_to llm_providers_path,
                notice: "Key removed for #{@provider.name}. #{fallback_note(@provider)}"
  end

  private

  def provider_params = params.require(:llm_provider).permit(:key, :name, :status, :notes)

  # Blank means unchanged. Submitting the form to edit a name must not silently
  # wipe the credential.
  def apply_api_key
    submitted = params.dig(:llm_provider, :api_key)
    return if submitted.blank?

    @provider.set_api_key!(submitted.strip, by: current_reviewer)
  end

  def fallback_note(provider)
    if provider.credentialed?
      "Falling back to #{provider.credential_env}."
    else
      "Nothing will route to it until a key is set."
    end
  end
end
