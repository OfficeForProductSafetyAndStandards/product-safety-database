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
      @mobile_number_verified = current_user.mobile_number_verified
    end

    def create
      @mobile_number_verified = current_user.mobile_number_verified
      if !@mobile_number_verified && user_params.has_key?(:mobile_number)
        current_user.mobile_number = user_params[:mobile_number]
        return render(:new) if !current_user.save(context: :mobile_number_change)
      end
      # To avoid the user being redirected back to "Resend Security Code" page after successfully introducing
      # the new secondary auth. code, we carry the original redirection path from where 2FA was triggered.
      require_secondary_authentication(redirect_to: session[:secondary_authentication_redirect_to])
    end

  private

    def current_operation
      current_user&.secondary_authentication_operation.presence || SecondaryAuthentication::DEFAULT_OPERATION
    end

    def hide_nav?
      true
    end

    def user_params
      params.require(:user).permit(:mobile_number)
    end
  end
end
