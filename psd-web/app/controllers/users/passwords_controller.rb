module Users
  class PasswordsController < Devise::PasswordsController
    skip_before_action :assert_reset_token_passed,
                       :require_no_authentication,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       only: :edit


    # TO DO: Hide user navigation header?
    # TO DO: Do we really want to skip declaration/introduction? Done for tests. Need to figure out desired behaviour.
    # TO DO: Is this safe to do?
    # TO DO: Refactor/Extract 2FA logic bit
    def edit
      # TO DO: Check if this conditional is correct
      if !current_user || (current_user && !is_fully_authenticated?)
        return render :invalid_link, status: :not_found if params[:reset_password_token].blank? || reset_token_invalid?
        return render :expired, status: :gone if reset_token_expired?

        sign_in(user_with_reset_token)
        warden.session(:user)[TwoFactorAuthentication::NEED_AUTHENTICATION] = true
        store_location_for(:user, edit_user_password_path)
        user_with_reset_token.send_new_otp

        return redirect_to user_two_factor_authentication_path
      end

      super
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

  private

    def resend_invitation_link_for(user)
      SendUserInvitationJob.perform_later(user.id, nil)
      redirect_to check_your_email_path
    end

    def reset_token_invalid?
      user_with_reset_token.blank?
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
