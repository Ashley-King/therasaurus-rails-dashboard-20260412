Rails.application.routes.draw do
  # Auth
  get "signin", to: "auth#new"
  post "signin", to: "auth#create"
  get "verify", to: "auth#verify"
  post "verify", to: "auth#confirm"
  delete "signout", to: "auth#destroy"

  # Create Account
  get "create-account", to: "create_account#new", as: :create_account
  post "create-account", to: "create_account#create"

  # Dashboard
  resource :dashboard, only: [ :show ], controller: "dashboard" do
    post :test_submit
  end

  # About You
  scope "about-you", module: :about_you do
    get "/", to: "professional_identities#show", as: :about_you
    resource :professional_identity, only: [ :show, :update ], path: "professional-identity"
    resource :primary_credential, only: [ :show ], path: "primary-credential"
    resource :education, only: [ :show ]
    resource :professional_development, only: [ :show ], path: "professional-development"
  end

  # Your Practice
  scope "your-practice", module: :your_practice do
    get "/", to: "practice_details#show", as: :your_practice
    resource :practice_details, only: [ :show ], path: "practice-details"
    resource :introduction, only: [ :show ]
    resource :clients_availability, only: [ :show ], path: "clients-availability"
    resource :location, only: [ :show ], path: "locations"
    resource :fees_payment, only: [ :show ], path: "fees-payment"
    resource :services_specialties, only: [ :show ], path: "services-specialties"
    resource :faq, only: [ :show ], path: "faqs"
  end

  # Account Settings
  scope "account-settings", module: :account_settings do
    get "/", to: "accounts#show", as: :account_settings
    resource :account, only: [ :show, :update ]
    resource :presigned_upload, only: [ :create ], path: "presigned-upload"
    resource :update_email, only: [ :show ], path: "update-email"
    resource :notification, only: [ :show ], path: "notifications"
    resource :membership, only: [ :show ]
  end

  # Health checks
  get "health", to: "health#show"
  get "up" => "rails/health#show", as: :rails_health_check

  root "auth#new"
end
