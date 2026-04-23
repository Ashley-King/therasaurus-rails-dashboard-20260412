Rails.application.routes.draw do
  mount Avo::Engine, at: Avo.configuration.root_path

  # Auth
  get "signin", to: "auth#new"
  post "signin", to: "auth#create"
  get "verify", to: "auth#verify"
  post "verify", to: "auth#confirm"
  delete "signout", to: "auth#destroy"

  # Create Account
  get "create-account", to: "create_account#new", as: :create_account
  post "create-account", to: "create_account#create"

  # Shared endpoints (used across multiple flows)
  get "zip-search", to: "zip_lookups#search", as: :zip_search

  # About You
  scope "about-you", module: :about_you do
    get "/", to: "professional_identities#show", as: :about_you
    resource :professional_identity, only: [ :show, :update ], path: "professional-identity"
    resource :primary_credential, only: [ :show, :update ], path: "primary-credential"
    resource :credential_upload, only: [ :create ], path: "credential-upload"
    resource :education, only: [ :show, :update ]
    get "colleges/search", to: "colleges#search", as: :college_search
    resource :professional_development, only: [ :show, :update ], path: "professional-development"
  end

  # Your Practice
  scope "your-practice", module: :your_practice do
    get "/", to: "practice_information#show", as: :your_practice
    resource :practice_information, only: [ :show, :update ], path: "practice-information", controller: "practice_information"
    resource :location, only: [ :show, :update ], path: "locations"
    resources :targeted_zips, only: [ :index, :create, :destroy ], path: "targeted-zips"
    resource :introduction, only: [ :show, :update ]
    resource :clients, only: [ :show, :update ]
    resource :availability, only: [ :show, :update ], controller: "availability"
    resource :accessibility, only: [ :show, :update ], controller: "accessibility"
    resource :fees_payment, only: [ :show ], path: "fees-payment"
    resource :services_specialties, only: [ :show ], path: "services-specialties"
    resource :social_media, only: [ :show, :update ], path: "social-media", controller: "social_media"
    resource :faq, only: [ :show ], path: "faqs"
  end

  # Account Settings
  scope "account-settings", module: :account_settings do
    get "/", to: "accounts#show", as: :account_settings
    resource :account, only: [ :show, :update ]
    resource :presigned_upload, only: [ :create ], path: "presigned-upload"
    resource :update_email, only: [ :show, :update ], path: "update-email" do
      post :confirm
      delete :cancel
    end
    resource :notification, only: [ :show ], path: "notifications"
    resource :membership, only: [ :show ]
  end

  # Admin tools (not mounted under Avo's /admin path to avoid engine routing
  # collision; the controller still enforces `current_user.is_admin?`).
  scope "admin-tools", module: :admin_tools do
    get "credentials/:id/document", to: "credential_documents#show", as: :admin_credential_document
  end

  # Health checks
  get "health", to: "health#show"
  get "up" => "rails/health#show", as: :rails_health_check

  root "auth#new"
end
