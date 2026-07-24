Rails.application.routes.draw do
  root "documents#index"

  resources :documents, only: %i[index new create show] do
    member do
      post :classify
      post :govern
    end
  end

  # Sign-in. Authorisation lives in policies; the session establishes who is
  # acting, and their Referent is what judgements attribute to.
  resource :session, only: %i[new create destroy]

  # The registry: what models exist, what they were asked, and who vouched.
  resources :llm_providers, only: %i[index new create edit update] do
    delete :credential, on: :member, action: :clear_credential
  end
  resources :llm_assignments, only: %i[create destroy]
  resources :llm_models, only: %i[index new create] do
    member do
      post :certify
      post :revoke
    end
  end
  resources :llm_invocations, only: %i[index]

  resources :flags, only: %i[update]

  # Answering an identity STOP: ground the name, or say it is not a subject.
  resources :mentions, only: [] do
    member do
      post :ground
      post :ignore
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
