class SessionsController < Devise::SessionsController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  skip_before_action :authenticate_user!, :authorize_user, :has_accepted_declaration, :set_current_user, :set_raven_context


  def new
    redirect_to user_openid_connect_omniauth_authorize_path
  end

  def signin
    request_and_store_token(auth_code, params[:request_path])

    redirect_path = is_relative(params[:request_path]) ? params[:request_path] : root_path
    redirect_to redirect_path
  rescue RestClient::ExceptionWithResponse => e
    redirect_to keycloak_login_url(params[:request_path]), alert: signin_error_message(e)
  end

  def logout
    ::KeycloakClient.instance.logout(refresh_token)
    redirect_to root_path
  end

  def sign_in; end

  def two_factor; end

  def reset_password; end

  def text_not_received; end

  def text_not_received_account_creation; end

  def check_your_email; end

  def new_password; end

  def link_expired; end

  def invite_expired; end

  def create_account; end


private

  def secondary_nav_items
    nil
  end

  def request_and_store_token(auth_code, redirect_url)
    self.keycloak_token = ::KeycloakClient.instance.exchange_code_for_token(auth_code, session_url_with_redirect(redirect_url))
  end

  def signin_error_message(error)
    error.is_a?(RestClient::Unauthorized) ? "Invalid email or password." : JSON(error.response)["error_description"]
  end

  def auth_code
    params.require(:code)
  end

  def is_relative(url)
    url =~ /^\/[^\/\\]/
  end
end
