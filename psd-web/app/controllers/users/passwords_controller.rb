module Users
  class PasswordsController < Devise::PasswordsController
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
