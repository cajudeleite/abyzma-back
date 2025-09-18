Rails.application.routes.draw do
  get "email_viewer/index"
  get "email_viewer/:id", to: "email_viewer#show", as: "email_viewer_show"
  namespace :admin do
      resources :cupons
      resources :phases
      resources :tickets

      root to: "cupons#index"
    end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # API routes
  namespace :api do
    namespace :v1 do
      get "phases/current", to: "phases#current_phase"
      get "phases", to: "phases#index"
      post '/create-checkout-session', to: 'checkout#create'
      post '/webhooks/stripe', to: 'webhooks#stripe'
      get '/webhooks/test', to: 'webhooks#test'
      get '/payment-success', to: 'payment_success#show'
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
