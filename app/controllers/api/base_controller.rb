class Api::BaseController < ActionController::Base
  skip_before_action :verify_authenticity_token
  skip_before_action
  prepend_before_action :authenticate_api_token!
  rescue_from ActiveRecord::RecordNotFound, with: :render_404


  private

  def authenticate_api_token!
    if (user = user_from_token)
      sign_in user, store: false
      user.update_last_activity_time!
    else
      render_unauthorized
    end
  end

  def token_from_header
    request.headers.fetch("Authorization", "").split(" ").last
  end

  def api_token
    @api_token ||= ApiToken.find_by(token: token_from_header)
  end

  # Only for use within authenticate_api_token! above
  # Use current_user/Current.user or current_account/Current.account within app controllers
  def user_from_token
    if api_token.present?
      api_token.touch(:last_used_at)
      api_token.user
    end
  end

  def render_unauthorized
    render json: { error: "Invalid Login" }, status: :unauthorized
  end

  def render_404
    render json: { error: "Not Found" }, status: :not_found
  end
end
