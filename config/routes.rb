Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "products#index"

  # Authentication routes
  get    "/login",  to: "sessions#new",     as: :new_session
  post   "/sessions", to: "sessions#create", as: :sessions
  delete "/logout", to: "sessions#destroy", as: :destroy_session

  get  "/register", to: "registrations#new",    as: :new_registration
  post "/registrations", to: "registrations#create", as: :registrations

  # Static pages (placeholders for now)
  get "/terms",   to: "pages#terms",   as: :terms
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/support", to: "pages#support", as: :support

  resources :products do
    member do
      get "select_variant"
    end
  end
end
