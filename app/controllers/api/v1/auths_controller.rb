class Api::V1::AuthsController < Api::BaseController
  skip_before_action :authenticate_api_token!

  # Requires email and password params
  # Returns an API token for the user if valid
  def create
    if user&.valid_password?(params[:password])
      render json: { token: token_by_name(ApiToken::DEFAULT_NAME) }
    else
      render_unauthorized
    end
  end

  def destroy
    if user&.valid_password?(params[:password])
      user.api_tokens.destroy_all
      head :ok
    else
      render_unauthorized
    end
  end

private

  def user
    @user ||= User.find_by(email: params[:email])
  end

  def sign_in_user
    user.remember_me = true
    sign_in user
  end

  def token_by_name(name)
    user.api_tokens.find_or_create_by!(name:).token
  end
end
