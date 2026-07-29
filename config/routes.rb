Rails.application.routes.draw do
  root "documents#index"

  resources :documents, only: %i[index new create show] do
    member do
      get :reading
      post :classify
      post :propose_identities
      post :govern
    end

    # Typing claims without seeing what the machine said. Its own path rather
    # than a mode of the document view, because the document view shows the
    # answers.
    resource :blind_reading, only: %i[show create], controller: "blind_readings" do
      get :comparison
    end
  end

  # The programmatic surface. A token acts as its Referent, so whatever calls
  # this attributes its judgements to itself.
  namespace :api do
    namespace :v1 do
      resources :documents, only: %i[index show create] do
        member do
          post :classify
          post :propose_identities
          post :govern
          post :profile
        end
        resources :mentions, only: :index
        resources :flags, only: :index

        # The act the programmatic surface exists for: a review decision the
        # application expects a person to make, made by an agent instead.
        resource :blind_reading, only: %i[show create], controller: "blind_readings" do
          get :comparison
        end
      end

      resources :mentions, only: [] do
        member do
          post :ground
          post :ignore
        end
      end

      resources :flags, only: :update

      # Reading only. Writing stays on REST, where the delegation gate lives.
      post "graphql", to: "graphql#execute"

      resources :llm_models, only: :index do
        member do
          post :certify
          post :revoke
        end
      end
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
