module Users
  class UnlocksController < Devise::UnlocksController
    skip_before_action :require_no_authentication,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       only: :show

    def show
      if passed_two_factor_authentication?
        # Devise password update requires the user to be signed out, as it relies on the "reset password token"
        # parameter and an user attempting to reset its password because does not remember it is not supposed to be
        # already signed in.
        # In order to be able to enforce 2FA, we need to to sign the user in.
        # Given this contradiction between needing it for 2FA but needing the opposite for the password update,
        # when the user gets redirected back after 2FA, we have to sign out the users before allowing them to
        # update their password.
        sign_out(:user)
        super
      else
        sign_in(user_with_unlock_token)
        warden.session(:user)[TwoFactorAuthentication::NEED_AUTHENTICATION] = true
        # Will redirect back to #edit after passing 2FA.
        # fullpath contains "reset_password_token", necessary for the further update.
        store_location_for(:user, request.fullpath)
        user_with_unlock_token.send_new_otp

        redirect_to user_two_factor_authentication_path
      end
    end

  private

    def passed_two_factor_authentication?
      return true if !Rails.configuration.two_factor_authentication_enabled

      user_signed_in? && user_with_unlock_token == current_user && is_fully_authenticated?
    end

    def user_with_unlock_token
      @user_with_unlock_token ||= begin
        unlock_token = Devise.token_generator.digest(self, :unlock_token, params[:unlock_token])

        User.find_by(unlock_token: unlock_token)
      end
    end
  end
end
