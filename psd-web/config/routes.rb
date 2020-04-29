require "sidekiq/web"
require "sidekiq/cron/web"

Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]

if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV["SIDEKIQ_USERNAME"]) &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"])
  end
end

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
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

  resources :investigations, path: "cases", only: %i[index show new], param: :pretty_id,
            concerns: %i[document_attachable] do
    member do
      get :status
      patch :status
      get :visibility
      patch :visibility
      get :edit_summary
      patch :edit_summary
      get :created
    end

    resources :collaborators, only: %i[index new create], path: "teams", path_names: { new: "add" }

    resource :coronavirus_related, only: %i[update show], path: "edit-coronavirus-related", controller: "investigations/coronavirus_related"
    resources :attachments, controller: "investigations/attachments", only: %i[index]

    resource :activity, controller: "investigations/activities", only: %i[show create new] do
      resource :comment, only: %i[create new]
    end

    resources :products, only: %i[new create index], controller: "investigations/products" do
      member do
        put :link, path: ""
        get :remove
        delete :unlink, path: ""
      end
    end
    resources :businesses, only: %i[index update show new create], controller: "investigations/businesses" do
      member do
        get :remove
        delete :unlink, path: ""
      end
    end

    resources :assign, controller: "investigations/assign", only: %i[show new create update]
    resources :corrective_actions, controller: "investigations/corrective_actions", only: %i[show new create update]
    resources :emails, controller: "investigations/emails", only: %i[show new create update]
    resources :phone_calls, controller: "investigations/phone_calls", only: %i[show new create update]
    resources :meetings, controller: "investigations/meetings", only: %i[show new create update]
    resources :alerts, controller: "investigations/alerts", only: %i[show new create update]
    resources :tests, controller: "investigations/tests", only: %i[show create update] do
      collection do
        get :new_request
        get :new_result
      end
    end
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

  get "your-teams" => "teams#index"
  resources :teams, only: %i[index show] do
    member do
      get :invite_to, path: "invite"
      put :invite_to, path: "invite"
      get :resend_invitation
    end
  end

  resources :teams, only: %i[index show] do
    member do
      get :invite_to, path: "invite"
      put :invite_to, path: "invite"
      get :resend_invitation
    end
  end

  namespace :help do
    get :terms_and_conditions, path: "terms-and-conditions"
    get :privacy_notice, path: "privacy-notice"
    get :about
  end



  match "/404", to: "errors#not_found", via: :all
  match "/403", to: "errors#forbidden", via: :all, as: :forbidden
  match "/500", to: "errors#internal_server_error", via: :all
  # This is the page that will show for timeouts, currently showing the same as an internal error
  match "/503", to: "errors#timeout", via: :all

  mount PgHero::Engine, at: "pghero"
  authenticated :user, ->(user) { user.is_opss? } do
    root to: redirect("/cases")
  end

  authenticated :user, ->(user) { !user.is_opss? } do
    root to: "homepage#non_opss"
  end

  unauthenticated do
    root to: "homepage#show"
  end
  # Handle old post-login redirect URIs from previous implementation which are still bookmarked
  match "/sessions/signin", to: redirect("/"), via: %i[get post]

  get "/health/all", to: "health#show"
end
# rubocop:enable Metrics/BlockLength
