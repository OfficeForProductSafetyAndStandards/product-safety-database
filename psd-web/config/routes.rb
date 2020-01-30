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
  mount GovukDesignSystem::Engine => "/", as: "govuk_design_system_engine"

  unless Rails.env.production? && (!ENV["SIDEKIQ_USERNAME"] || !ENV["SIDEKIQ_PASSWORD"])
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    resource :session, only: [] do
      get :logout, to: "sessions#destroy"
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
  resources :project, controller: "investigations/project", only: %i[new create]
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
    resources :project,          controller: "project",           only: %i[show new create]
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
      put :resend_invitation
    end
  end

  resources :teams, only: %i[index show] do
    member do
      get :invite_to, path: "invite"
      put :invite_to, path: "invite"
      put :resend_invitation
    end
  end

  namespace :help do
    get :terms_and_conditions, path: "terms-and-conditions"
    get :privacy_notice, path: "privacy-notice"
    get :about
  end



  match "/404", to: "errors#not_found", via: :all
  match "/403", to: "errors#forbidden", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  # This is the page that will show for timeouts, currently showing the same as an internal error
  match "/503", to: "errors#timeout", via: :all

  mount PgHero::Engine, at: "pghero"

  root to: "homepage#show"
end
# rubocop:enable Metrics/BlockLength
