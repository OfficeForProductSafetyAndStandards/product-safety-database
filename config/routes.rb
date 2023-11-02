require "constraints/domain_inclusion_constraint"
require "constraints/domain_exclusion_constraint"
require "sidekiq/web"
require "sidekiq-scheduler/web"

if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV["SIDEKIQ_USERNAME"]) &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"])
  end
end

Rails.application.routes.draw do
  mount GovukDesignSystem::Engine => "/", as: "govuk_design_system_engine"

  unless Rails.env.production? && (!ENV["SIDEKIQ_USERNAME"] || !ENV["SIDEKIQ_PASSWORD"])
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, path: "", path_names: { sign_in: "sign-in", sign_out: "sign-out" }, controllers: { sessions: "users/sessions", passwords: "users/passwords", unlocks: "users/unlocks" } do
    get "reset-password", to: "users/passwords#new", as: :new_user_password
  end

  devise_scope :user do
    resource :check_your_email, path: "check-your-email", only: :show, controller: "users/check_your_email"
    get "missing-mobile-number", to: "users#missing_mobile_number"
    post "sign-out-before-resetting-password", to: "users/passwords#sign_out_before_resetting_password", as: :sign_out_before_resetting_password
    get "remove_user", to: "users#remove", as: :remove_user
    delete "delete", to: "users#delete", as: :delete_user
  end

  resource :password_changed, controller: "users/password_changed", only: :show, path: "password-changed"
  get "two-factor", to: "secondary_authentications#new", as: :new_secondary_authentication
  post "two-factor", to: "secondary_authentications#create", as: :secondary_authentication

  get "text-not-received", to: "secondary_authentications/resend_code#new", as: :new_resend_secondary_authentication_code
  post "text-not-received", to: "secondary_authentications/resend_code#create", as: :resend_secondary_authentication_code

  resource :account, only: [:show], controller: :account do
    resource :name, controller: :account_name, only: %i[show update]
  end

  resources :users, only: [:update] do
    member do
      get "complete-registration", action: :complete_registration
      post "sign-out-before-accepting-invitation", action: :sign_out_before_accepting_invitation
    end
  end

  # Main PSD app
  constraints DomainExclusionConstraint.new(ENV.fetch("PSD_HOST_SUPPORT")) do
    mount Prism::Engine => "/prism"

    concern :document_attachable do
      resources :documents, controller: "documents" do
        member do
          get :remove
        end
      end
    end

    concern :document_uploadable do
      resources :document_uploads, controller: "document_uploads" do
        member do
          get :remove
        end
      end
    end

    concern :image_uploadable do
      resources :image_uploads, controller: "image_uploads", except: %i[edit update] do
        member do
          get :remove
        end
      end
    end

    namespace :declaration do
      get :index, path: ""
      post :accept
    end

    namespace :introduction do
      get :overview
      get :report_products
      get :track_investigations
      get :share_data
      get :skip
    end

    resources :create_a_case_page, controller: "create_a_case_page", only: %i[index]

    resources :ts_investigation, controller: "investigations/ts_investigations", only: %i[show new create update]

    scope :investigation, path: "", as: :investigation do
      resources :ts_investigation, only: [], concerns: %i[document_attachable]
    end

    scope :investigation, path: "", module: "investigations", as: :investigation do
      resources :ts_investigation, controller: "ts_investigations", only: %i[show new create update]
    end

    resource :investigations, only: [], path: "cases" do
      resource :search, only: :show

      get "your-cases", to: "investigations#your_cases", as: "your_cases"
      get "team-cases", to: "investigations#team_cases", as: "team_cases"
      get "assigned-cases", to: "investigations#assigned_cases", as: "assigned_cases"
      get "all-cases", to: "investigations#index"
    end

    get "cases/new", to: "ts_investigations#new"

    resources :investigations,
              path: "cases",
              only: %i[show index destroy],
              param: :pretty_id,
              concerns: %i[document_attachable image_uploadable] do
      member do
        get :created
        get :cannot_close
        get :confirm_deletion
      end

      resource :status, only: %i[], controller: "investigations/status" do
        get :close
        get :reopen
        patch :close
        patch :reopen
      end

      resource :visibility, only: %i[], controller: "investigations/visibility" do
        get :show
        get :restrict
        get :unrestrict
        patch :restrict
        patch :unrestrict
      end

      resource :summary, only: %i[edit update], controller: "investigations/summary"

      resources :collaborators, only: %i[index new create edit update], path: "teams", path_names: { new: "add" }

      resource :coronavirus_related, only: %i[update show], path: "edit-coronavirus-related", controller: "investigations/coronavirus_related"
      resource :notifying_country, only: %i[update edit], path: "edit-notifying-country", controller: "investigations/notifying_country"
      resource :overseas_regulator, only: %i[update edit], path: "edit-overseas-regulator", controller: "investigations/overseas_regulator"
      resource :risk_level, only: %i[update show], path: "edit-risk-level", controller: "investigations/risk_level"
      resource :risk_validations, only: %i[edit update], path: "validate-risk-level", controller: "investigations/risk_validations"
      resource :reference_numbers, only: %i[edit update], controller: "investigations/reference_numbers"
      resource :case_names, only: %i[edit update], controller: "investigations/case_names"
      resource :safety_and_compliance, only: %i[edit update], path: "edit-safety-and-compliance", controller: "investigations/safety_and_compliance"
      resource :reported_reason, only: %i[edit update], path: "edit-reported-reason", controller: "investigations/reported_reason"
      resources :images, controller: "investigations/images", only: %i[index], path: "images"
      resources :supporting_information, controller: "investigations/supporting_information", path: "supporting-information", as: :supporting_information, only: %i[index]

      resources :actions, controller: "investigations/actions", path: "actions", as: :actions, only: %i[index create]

      resource :activity, controller: "investigations/activities", only: %i[show create] do
        resource :comment, only: %i[create new]
      end

      resources :prism_risk_assessments, controller: "investigations/prism_risk_assessments", path: "prism-risk-assessments", only: %i[new create] do
        collection do
          get :choose_product
        end
      end

      resources :risk_assessments, controller: "investigations/risk_assessments", path: "risk-assessments", only: %i[new create show edit update] do
        resource :update_case_risk_level, only: %i[show update], path: "update-case-risk-level", controller: "investigations/update_case_risk_level_from_risk_assessment"
      end

      resources :products, only: %i[new create index], controller: "investigations/products" do
        collection do
          post :find
        end
      end

      resources :investigation_products, only: %i[remove unlink], controller: "investigations/investigation_products" do
        member do
          get :owner
          get :remove
          delete :unlink, path: ""
        end
      end

      resource :business_types, controller: "investigations/business_types", path: "businesses/with-type", only: %i[new create]
      resources :businesses, controller: "investigations/businesses" do
        member do
          get :remove
        end
      end

      resources :phone_calls, controller: "investigations/phone_calls", only: :show, constraints: { id: /\d+/ }, path: "phone-calls"
      resources :emails, controller: "investigations/emails", only: :show, constraints: { id: /\d+/ }
      resources :meetings, controller: "investigations/meetings", only: :show, constraints: { id: /\d+/ }

      resources :ownership, controller: "investigations/ownership", only: %i[show new create update], path: "assign"

      resources :accident_or_incidents_type, controller: "investigations/accident_or_incidents_type", only: %i[new create]
      resources :accident_or_incidents, controller: "investigations/accident_or_incidents", only: %i[show new create edit update]

      resources :correspondence, controller: "investigations/correspondence_routing", only: %i[new create]
      resources :emails, controller: "investigations/record_emails", only: %i[new create edit update]
      resources :phone_calls, controller: "investigations/record_phone_calls", only: %i[new create edit update], path: "phone-calls"
      resources :alerts, controller: "investigations/alerts", only: %i[show new create update] do
        collection do
          get :about
          post :preview
        end
      end

      resources :test_results, controller: "investigations/test_results", only: %i[new show edit update create], path: "test-results" do
        collection do
          resource :funding_source, controller: "investigations/test_results/funding_source", only: %i[new create], path: "funding-source"
          resource :funding_certificate, controller: "investigations/test_results/funding_certificate", only: %i[new create], path: "funding-certificate"

          put :create_draft, path: "confirm"
          get :confirm
        end
      end

      resources :corrective_actions, controller: "investigations/corrective_actions", only: %i[new show create edit update], path: "corrective-actions"
    end

    resources :case_exports, only: :show do
      collection do
        get :generate
      end
    end

    resources :business_exports, only: :show do
      collection do
        get :generate
      end
    end

    resource :products, only: [], path: "products" do
      get "your-products", to: "products#your_products", as: "your"
      get "team-products", to: "products#team_products", as: "team"
      get "all-products", to: "products#index", as: "all"
    end

    resources :products, except: %i[destroy], concerns: %i[document_uploadable image_uploadable] do
      member do
        get :owner
      end

      collection do
        get :duplicate_check, to: "products/duplicate_checks#new", path: "duplicate-check"
        post :duplicate_check, to: "products/duplicate_checks#create", path: "duplicate-check"

        scope "/bulk-upload" do
          get "triage", to: "bulk_products#triage", as: "triage_bulk_upload"
          put "triage", to: "bulk_products#triage"
          get "no-upload-unsafe", to: "bulk_products#no_upload_unsafe", as: "no_upload_unsafe_bulk_upload"
          get "no-upload-mixed", to: "bulk_products#no_upload_mixed", as: "no_upload_mixed_bulk_upload"

          scope ":bulk_products_upload_id" do
            get "create-case", to: "bulk_products#create_case", as: "create_case_bulk_upload"
            put "create-case", to: "bulk_products#create_case"
            get "create-business", to: "bulk_products#create_business", as: "create_business_bulk_upload"
            put "create-business", to: "bulk_products#create_business"
            get "add-business-details", to: "bulk_products#add_business_details", as: "add_business_details_bulk_upload"
            put "add-business-details", to: "bulk_products#add_business_details"
            get "upload-products-file", to: "bulk_products#upload_products_file", as: "upload_products_file_bulk_upload"
            put "upload-products-file", to: "bulk_products#upload_products_file"
            get "resolve-duplicate-products", to: "bulk_products#resolve_duplicate_products", as: "resolve_duplicate_products_bulk_upload"
            put "resolve-duplicate-products", to: "bulk_products#resolve_duplicate_products"
            get "review-products", to: "bulk_products#review_products", as: "review_products_bulk_upload"
            put "review-products", to: "bulk_products#review_products"
            get "cancel-and-reupload", to: "bulk_products#cancel_and_reupload", as: "cancel_and_reupload_bulk_upload"
            get "choose-products-for-corrective-actions", to: "bulk_products#choose_products_for_corrective_actions", as: "choose_products_for_corrective_actions_bulk_upload"
            put "choose-products-for-corrective-actions", to: "bulk_products#choose_products_for_corrective_actions"
            get "create-corrective-action", to: "bulk_products#create_corrective_action", as: "create_corrective_action_bulk_upload"
            put "create-corrective-action", to: "bulk_products#create_corrective_action"
            get "confirm", to: "bulk_products#confirm", as: "confirm_bulk_upload"
            put "confirm", to: "bulk_products#confirm"
          end
        end
      end

      resource :duplicate_checks, controller: "products/duplicate_checks", only: %i[show], path: "duplicate-check" do
        member do
          post :confirm
        end
      end

      resources :recalls, only: %i[show update], controller: "products/recalls" do
        collection do
          post :pdf
        end
      end
    end

    resource :businesses, only: [], path: "businesses" do
      get "your-businesses", to: "businesses#your_businesses", as: "your"
      get "team-businesses", to: "businesses#team_businesses", as: "team"
      get "all-businesses", to: "businesses#index", as: "all"
    end

    resources :investigation_products, only: %i[], param: :id do
      resource :batch_numbers, only: %i[edit update], path: "edit-batch-numbers", controller: "investigation_products/batch_numbers"
      resource :customs_code, only: %i[edit update], path: "edit-customs-code", controller: "investigation_products/customs_codes"
      resource :ucr_numbers, only: %i[edit update destroy], path: "edit-ucr-numbers", controller: "investigation_products/ucr_numbers" do
        collection do
          post :add_ucr_number
        end
        get "/delete/:id" => "investigation_products/ucr_numbers#destroy", as: "delete"
      end

      resource :number_of_affected_units, only: %i[edit update], param: :id, path: "edit-number-of-affected-units", controller: "investigation_products/number_of_affected_units"
    end

    resource :prism_risk_assessments, only: [], path: "prism-risk-assessments" do
      get "your-prism-risk-assessments", to: "prism_risk_assessments#your_prism_risk_assessments", as: "your"
      get "team-prism-risk-assessments", to: "prism_risk_assessments#team_prism_risk_assessments", as: "team"
      get "all-prism-risk-assessments", to: "prism_risk_assessments#index", as: "all"
      get "add-to-case", to: "prism_risk_assessments#add_to_case", as: "add_to_case"
      post "add-to-case", to: "prism_risk_assessments#add_to_case"
    end

    resources :businesses, except: %i[new create destroy], concerns: %i[document_attachable] do
      resources :locations do
        member do
          get :remove
        end
      end
      resources :contacts do
        member do
          get :remove
        end
      end
    end

    resources :product_exports do
      collection do
        get :generate
      end
    end
  end

  # Support portal
  constraints DomainInclusionConstraint.new(ENV.fetch("PSD_HOST_SUPPORT")) do
    mount SupportPortal::Engine => "/"
  end

  resources :teams, only: %i[index show] do
    resources :invitations, only: %i[new create] do
      member do
        put :resend
      end
    end
  end

  namespace :help do
    get :terms_and_conditions, path: "terms-and-conditions"
    get :privacy_notice, path: "privacy-notice"
    get :about
    get :accessibility
    get :cookies_policy, path: "cookies"
  end

  resource :cookie_form, only: [:create]

  match "/404", to: "errors#not_found", via: :all
  match "/403", to: "errors#forbidden", via: :all, as: :forbidden
  match "/500", to: "errors#internal_server_error", via: :all
  # This is the page that will show for timeouts, currently showing the same as an internal error
  match "/503", to: "errors#timeout", via: :all

  mount PgHero::Engine, at: "pghero"

  authenticated :user do
    root to: "homepage#authenticated", as: "authenticated_root"
  end

  unauthenticated do
    root to: "homepage#show", as: "unauthenticated_root"
  end
  # Handle old post-login redirect URIs from previous implementation which are still bookmarked
  match "/sessions/signin", to: redirect("/"), via: %i[get post]

  get "/health/all", to: "health#show"
end
