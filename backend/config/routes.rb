Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up and /health that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  # Google OAuth認証関連のルーティング
  get 'auth/google_oauth2', to: 'google_auth#new'
  get 'auth/google_oauth2/callback', to: 'google_auth#callback'
  delete 'auth/google_oauth2', to: 'google_auth#disconnect', as: :disconnect_google

  # ログイン・ユーザー登録関連のルーティング
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  get 'signup', to: 'users#new'
  post 'signup', to: 'users#create'
  get 'dashboard', to: 'dashboard#index'

  # Files API endpoints
  get 'files', to: 'files#index'
  post 'upload', to: 'files#upload'
  post 'folders', to: 'files#create_folder'
  post 'set_working_folder', to: 'files#set_working_folder'
  post 'create_root_folder', to: 'files#create_root_folder'

  # ルートページを認証状態に応じて振り分け
  root 'home#index'
end
