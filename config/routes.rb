Rails.application.routes.draw do
  # Auth
  get "signin", to: "auth#new"
  post "signin", to: "auth#create"
  get "verify", to: "auth#verify"
  post "verify", to: "auth#confirm"
  delete "signout", to: "auth#destroy"

  # Dashboard
  resource :dashboard, only: [ :show ], controller: "dashboard" do
    post :test_submit
    scope module: :dashboard do
      resource :professional_identity, only: [ :show, :update ]
      resource :practice_details, only: [ :show, :update ]
      resource :clients_availability, only: [ :show, :update ]
      resource :fees, only: [ :show, :update ]
      resource :services_specialties, only: [ :show, :update ]
    end
  end

  # About You
  scope "about-you", module: :about_you do
    get "/", to: "professional_identities#show", as: :about_you
    resource :professional_identity, only: [ :show, :update ], path: "professional-identity"
    resource :update_email, only: [ :show ], path: "update-email"
    resource :primary_credential, only: [ :show ], path: "primary-credential"
    resource :education, only: [ :show ]
    resource :professional_development, only: [ :show ], path: "professional-development"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "auth#new"
end
