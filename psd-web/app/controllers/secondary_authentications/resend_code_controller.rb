module SecondaryAuthentications
  class ResendCodeController < ApplicationController
    skip_before_action :authenticate_user!,
                       :set_current_user,
                       :require_secondary_authentication,
                       :set_raven_context,
                       :authorize_user,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       :set_cache_headers

    def new
      @mobile_number_change_allowed = !current_user.mobile_number_verified
    end

    def create
      @mobile_number_change_allowed = !current_user.mobile_number_verified
      if resend_code_form.save!
        # To avoid the user being redirected back to "Resend Security Code" page after successfully introducing
        # the new secondary auth. code, we carry the original redirection path from where 2FA was triggered.
        require_secondary_authentication(redirect_to: session[:secondary_authentication_redirect_to])
      else
        current_user.errors.merge!(resend_code_form.errors)
        render(:new)
      end
    end

  private

    def current_operation
      current_user&.secondary_authentication_operation.presence || SecondaryAuthentication::DEFAULT_OPERATION
    end

    def hide_nav?
      true
    end

    def resend_code_form
      @resend_code_form ||= ResendSecondaryAuthenticationCodeForm.new(mobile_number: params[:mobile_number], user: current_user)
    end
  end
end
