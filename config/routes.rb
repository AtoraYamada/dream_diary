Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest

  # JSON API
  namespace :api do
    namespace :v1 do
      # 認証API（devise_scopeでDeviseと連携）
      devise_scope :user do
        post 'sessions', to: 'sessions#create', defaults: { format: :json }
        delete 'sessions', to: 'sessions#destroy', defaults: { format: :json }
        post 'registrations', to: 'registrations#create', defaults: { format: :json }
      end

      resources :dreams do
        collection do
          get :search
          get :overflow
        end
      end

      resources :tags, only: [:index, :destroy] do
        collection do
          get :suggest
        end
      end
    end
  end

  # Pages routes (静的ページ)
  root 'pages#index'
  get 'auth', to: 'pages#auth'
  get 'library', to: 'pages#library'
  get 'list', to: 'pages#list'

  # Defines the root path route ("/")
  # root "posts#index"
end
