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
  # Session management (login/logout)
  resource :session, only: [:new, :create, :destroy] do
    collection do
      get :new, as: :new_session  # login form
      post :create               # process login
      delete :destroy            # logout
    end
  end

  # User registration
  resource :registration, only: [:new, :create] do
    collection do
      get :new, as: :new_registration  # signup form
      post :create                     # process signup
    end
  end

  # Password reset workflow
  resources :password_resets, only: [:new, :create, :show, :update], param: :token do
    collection do
      get :new, as: :new_password_reset    # request reset form
      post :create                         # send reset email
    end
    member do
      get :show, as: :password_reset       # reset form with token
      patch :update                        # process password reset
    end
  end

  # Email verification
  resources :email_verifications, only: [:show, :create], param: :token do
    collection do
      post :create, as: :resend_email_verification  # resend verification
    end
    member do
      get :show, as: :email_verification            # verify email with token
    end
  end

  resources :products do
    member do
      get "select_variant"
    end
  end

  # Shopping Cart routes
  resource :cart, only: [ :show ] do
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end
end
