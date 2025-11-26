Rails.application.routes.draw do
  devise_for :users

  # Home = list of mock interviews
  root "assistant_sessions#index"

  resources :assistant_sessions, only: [:index, :new, :create, :show] do
    member do
      get :report  # /assistant_sessions/:id/report
    end

    resources :messages, only: :create
  end
end
