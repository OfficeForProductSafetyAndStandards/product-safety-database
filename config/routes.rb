require "sidekiq/web"
require "sidekiq/cron/web"

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

  concern :document_attachable do
    resources :documents, controller: "documents" do
      collection do
        # TODO: Fix this route - results in a non-descript alias and path with new/new
        resources :new, controller: "documents_flow", only: %i[show new create update]
      end
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

  resources :enquiry, controller: "investigations/enquiry", only: %i[show new create update]
  resources :allegation, controller: "investigations/allegation", only: %i[show new create update]
  resources :project, controller: "investigations/project", only: %i[show new create update]
  resources :ts_investigation, controller: "investigations/ts_investigations", only: %i[show new create update]

  scope :investigation, path: "", as: :investigation do
    resources :allegation,       only: [], concerns: %i[document_attachable]
    resources :enquiry,          only: [], concerns: %i[document_attachable]
    resources :project,          only: [], concerns: %i[document_attachable]
    resources :ts_investigation, only: [], concerns: %i[document_attachable]
  end

  scope :investigation, path: "", module: "investigations", as: :investigation do
    resources :enquiry,          controller: "enquiry",           only: %i[show new create update]
    resources :allegation,       controller: "allegation",        only: %i[show new create update]
    resources :project,          controller: "project",           only: %i[show new create update]
    resources :ts_investigation, controller: "ts_investigations", only: %i[show new create update]
  end

  resource :investigations, only: [], path: "cases" do
    resource :search, only: :show
  end

  resources :investigations,
            path: "cases",
            only: %i[index show new],
            param: :pretty_id,
            concerns: %i[document_attachable] do
    member do
      get :created
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
    resource :risk_level, only: %i[update show], path: "edit-risk-level", controller: "investigations/risk_level"
    resource :risk_validations, only: %i[edit update], path: "validate-risk-level", controller: "investigations/risk_validations"
    resource :safety_and_compliance, only: %i[edit update], path: "edit-safety-and-compliance", controller: "investigations/safety_and_compliance"
    resources :images, controller: "investigations/images", only: %i[index], path: "images"
    resources :supporting_information, controller: "investigations/supporting_information", path: "supporting-information", as: :supporting_information, only: %i[index new create]
    get "add-to-case", to: "investigations/supporting_information#add_to_case", as: "add_to_case"

    resources :actions, controller: "investigations/actions", path: "actions", as: :actions, only: %i[index create]

    resource :activity, controller: "investigations/activities", only: %i[show create] do
      resource :comment, only: %i[create new]
    end

    resources :risk_assessments, controller: "investigations/risk_assessments", path: "risk-assessments", only: %i[new create show edit update] do
      resource :update_case_risk_level, only: %i[show update], path: "update-case-risk-level", controller: "investigations/update_case_risk_level_from_risk_assessment"
    end

    resources :products, only: %i[new create index], controller: "investigations/products" do
      member do
        put :link, path: ""
        get :remove
        delete :unlink, path: ""
      end
    end

    resources :businesses, only: %i[index update show new create destroy], controller: "investigations/businesses" do
      member { get :remove }
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
        put :create_draft, path: "confirm"
        get :confirm
      end
    end

    resources :corrective_actions, controller: "investigations/corrective_actions", only: %i[new show create edit update], path: "corrective-actions"
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

  resources :products, except: %i[new create destroy], concerns: %i[document_attachable]

  resources :product_exports do
    collection do
      get :generate
    end
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
  end

  match "/404", to: "errors#not_found", via: :all
  match "/403", to: "errors#forbidden", via: :all, as: :forbidden
  match "/500", to: "errors#internal_server_error", via: :all
  # This is the page that will show for timeouts, currently showing the same as an internal error
  match "/503", to: "errors#timeout", via: :all

  mount PgHero::Engine, at: "pghero"
  authenticated :user, ->(user) { user.is_opss? } do
    root to: redirect("/cases"), as: "authenticated_opss_root"
  end

  authenticated :user, ->(user) { !user.is_opss? } do
    root to: "homepage#non_opss", as: "authenticated_msa_root"
  end

  unauthenticated do
    root to: "homepage#show", as: "unauthenticated_root"
  end
  # Handle old post-login redirect URIs from previous implementation which are still bookmarked
  match "/sessions/signin", to: redirect("/"), via: %i[get post]

  get "/health/all", to: "health#show"
end
