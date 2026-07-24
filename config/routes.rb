Rails.application.routes.draw do
  root "documents#index"

  resources :documents, only: %i[index new create show] do
    member do
      post :classify
      post :govern
    end
  end

  # Disposing of a flag is an accountable act, so it needs a named reviewer.
  # There is no authentication here -- this only establishes WHO is answering,
  # which the architecture requires; it does not establish that they may.
  resource :reviewer, only: %i[new create destroy]

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
