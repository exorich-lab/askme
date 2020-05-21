Rails.application.routes.draw do
  root to: 'users#index'

  get 'sign_up' => 'users#new'
  get 'log_out' => 'sessions#destroy'
  get 'log_in' => 'sessions#new'

  resources :questions, except: %i[show new index]
  resources :users
  resources :sessions, only: %i[new create destroy]
end
