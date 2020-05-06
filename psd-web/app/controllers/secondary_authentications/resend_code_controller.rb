module SecondaryAuthentications
  class ResendCodeController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :set_current_user
    skip_before_action :require_secondary_authentication
    skip_before_action :set_raven_context
    skip_before_action :authorize_user
    skip_before_action :has_accepted_declaration
    skip_before_action :has_viewed_introduction
    skip_before_action :set_cache_headers

    def show; end

    def create
      # To avoid the user being redirected back to "Resend Security Code" page after successfully introducing
      # the new secondary auth. code, we carry the original redirection path from where 2FA was triggered.
      require_secondary_authentication(redirect_to: session[:secondary_authentication_redirect_to])
    end

  private

    def hide_nav?
      true
    end
  end
end
