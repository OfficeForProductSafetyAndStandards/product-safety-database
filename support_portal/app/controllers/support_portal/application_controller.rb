module SupportPortal
  class ApplicationController < ActionController::Base
    include Pagy::Backend

    include CacheConcern
    include HttpAuthConcern
    include SecondaryAuthenticationConcern
    include SentryConfigurationConcern

    protect_from_forgery with: :exception
    before_action :authenticate_user!
    before_action :set_paper_trail_whodunnit
    before_action :check_current_user_status
    before_action :ensure_secondary_authentication
    before_action :require_secondary_authentication
    before_action :set_sentry_context
    before_action :set_cache_headers

    add_flash_types :confirmation

    helper_method :current_user

    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

    rescue_from "ActiveRecord::RecordNotFound" do |_e|
      redirect_to "/404"
    end

    def check_current_user_status
      return unless user_signed_in?

      if current_user.access_locked? || current_user.deleted? || !current_user.has_role?("support_portal")
        sign_out current_user
        redirect_to "/"
      end
    end
  end
end
