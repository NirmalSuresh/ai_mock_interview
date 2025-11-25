Rails.application.routes.draw do
  root "pages#home"

  resources :interviews, only: [:new, :create, :show] do
    post :answer
    post :timeout
    get  :summary
  end

  resources :assistant_sessions, only: [:index]
end
