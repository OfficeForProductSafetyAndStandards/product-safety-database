module Users
  class UnlocksController < Devise::UnlocksController
    skip_before_action :require_no_authentication,
                       :has_accepted_declaration,
                       :has_viewed_introduction,
                       only: :show

    def show
      super
    rescue ActiveRecord::RecordNotFound
      render "invalid_link", status: :not_found
    end

  private

    def passed_two_factor_authentication?
      return true if !Rails.configuration.two_factor_authentication_enabled

      user_signed_in? && user_with_unlock_token == current_user && is_fully_authenticated?
    end

    def user_with_unlock_token
      @user_with_unlock_token ||= begin
        unlock_token = Devise.token_generator.digest(self, :unlock_token, params[:unlock_token])

        User.find_by!(unlock_token: unlock_token)
      end
    end

    def user_id_for_secondary_authentication
      user_with_unlock_token.id
    end

    def current_operation
      SecondaryAuthentication::UNLOCK_OPERATION
    end
  end
end
