module Users
  class PasswordsController < Devise::PasswordsController
    def create
      super do |resource|
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

    def reset_password_form
      @reset_password_form ||= ResetPasswordForm.new(resource_params.permit(:email))
    end

    def reset_password_token_just_expired?
      resource.errors.full_messages_for(:reset_password_token).any?
    end

    def after_sending_reset_password_instructions_path_for(_resource_name)
      check_your_email_path
    end
  end
end
