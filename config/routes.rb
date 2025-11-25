Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :interviews, only: [:new, :create, :show]

  post "interviews/:id/answer", to: "interviews#answer", as: :answer_interview

  resources :assistant_sessions, only: [:index]
end
