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
