module Users
  class PasswordsController < Devise::PasswordsController
    def update
      super do |_resource|
        if reset_password_token_just_expired?
          return render :expired
        end
      end
    end

  private

    def reset_password_token_just_expired?
      resource.errors.full_messages_for(:reset_password_token).any?
    end
  end
end
