Rails.application.routes.draw do
  devise_for :users

  root "assistant_sessions#index"

  resources :assistant_sessions, only: [:index, :new, :create, :show] do
    resources :messages, only: [:create]
  end
end
