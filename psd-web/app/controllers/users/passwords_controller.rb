module Users
  class PasswordsController < Devise::PasswordsController
    skip_before_action :assert_reset_token_passed, only: :edit

    def edit
      return render :invalid_link, status: :not_found if params[:reset_password_token].blank?
      return render :invalid_link, status: :not_found if reset_token_invalid?
      return render :expired, status: :gone if reset_token_expired?

      super
    end

    def create
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
