Rails.application.routes.draw do
  devise_for :users

  root "assistant_sessions#index"

  resources :assistant_sessions, only: [:index, :new, :create, :show] do
    member do
      get :final_report
    end

    resources :messages, only: [:create]
  end
end
