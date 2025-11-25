Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :interviews, only: [:new, :create, :show] do
  post :answer, on: :member
  post :timeout, on: :member
  get  :summary, on: :member
end


  resources :assistant_sessions, only: [:index]
end
