Rails.application.routes.draw do
  devise_for :users

  resources :interviews do
    member do
      post :answer
      post :timeout
      get :summary
    end
  end

  resources :assistant_sessions, only: [:index, :show]

  root "pages#home"
end
