Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up and /health that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  # ログイン関連のルーティング
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  get 'dashboard', to: 'dashboard#index'

  # Files API endpoints
  get 'files', to: 'files#index'
  post 'upload', to: 'files#upload'
  post 'folders', to: 'files#create_folder'

  # ルートページをログインページに設定
  root 'sessions#new'
end
