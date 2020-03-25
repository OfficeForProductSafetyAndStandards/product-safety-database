module Users
  class PasswordsController < Devise::PasswordsController
    skip_before_action :assert_reset_token_passed,
                       :require_no_authentication,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       only: :edit

    def edit
      return render :invalid_link, status: :not_found if reset_token_invalid?
      return render :expired, status: :gone if reset_token_expired?

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
        sign_in(user_with_reset_token)
        warden.session(:user)[TwoFactorAuthentication::NEED_AUTHENTICATION] = true
        # Will redirect back to #edit after passing 2FA.
        # fullpath contains "reset_password_token", necessary for the further update.
        store_location_for(:user, request.fullpath)
        user_with_reset_token.send_new_otp

        redirect_to user_two_factor_authentication_path
      end
    end

    def create
      user = User.find_by(email: params[:user][:email])
      return resend_invitation_link_for(user) if user && !user.has_completed_registration?

      super do |resource|
        suppress_email_not_found_error

        if reset_password_form.invalid?
          resource.errors.clear
          resource.errors.merge!(reset_password_form.errors)
          return render :new
        end
      end
    end

    def update
      super do |_resource|
        if reset_password_token_just_expired?
          return render :expired
        end
      end
    end

    # Overrides from ApplicationController in order to hide the the main navigation links
    # when the user lands at the password edition page after being signed in by 2FA.
    def hide_nav?
      true
    end

  private

    def passed_two_factor_authentication?
      return true if !Rails.configuration.two_factor_authentication_enabled

      user_signed_in? && is_fully_authenticated?
    end

    def resend_invitation_link_for(user)
      SendUserInvitationJob.perform_later(user.id, nil)
      redirect_to check_your_email_path
    end

    def reset_token_invalid?
      params[:reset_password_token].blank? || user_with_reset_token.blank?
    end

    def reset_token_expired?
      !user_with_reset_token.reset_password_period_valid?
    end

    def user_with_reset_token
      @user_with_reset_token ||= User.find_by(reset_password_token: hashed_reset_token)
    end

    def hashed_reset_token
      Devise.token_generator.digest(User, :reset_password_token, params[:reset_password_token])
    end

    def suppress_email_not_found_error
      return unless email_not_found_first_error?

      resource.errors.delete(:email)
    end

    def email_not_found_first_error?
      resource.errors.details.dig(:email).include?(error: :not_found)
    end

    def reset_password_form
      @reset_password_form ||= ResetPasswordForm.new(resource_params.permit(:email))
    end

    def reset_password_token_just_expired?
      resource.errors[:reset_password_token].any?
    end

    def after_sending_reset_password_instructions_path_for(_resource_name)
      check_your_email_path
    end
  end
end
