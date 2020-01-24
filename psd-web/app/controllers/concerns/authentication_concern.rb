module AuthenticationConcern
  extend ActiveSupport::Concern

  include Pundit

  include LoginHelper

  def initialize
    # Ensure that the Keycloak gem never attempts to fetch a token from the cookie by returning nil from the lambda.
    # This is still required, since the Keycloak gem calls the lambda if an empty token is passed in before login.
    Keycloak.proc_cookie_token = -> { nil }
    super
  end

  def authenticate_user!
    unless user_signed_in? || try_refresh_token
      redirect_to user_openid_connect_omniauth_authorize_path
      # redirect_to helpers.keycloak_login_url(request.original_fullpath)
    end
  end

  def user_signed_in?
    @user_signed_in ||= KeycloakClient.instance.user_signed_in?(access_token)
  end

  def set_current_user
    return unless user_signed_in?

    user_info = KeycloakClient.instance.user_info(access_token)

    begin
      User.current = User.find_or_create_by!(id: user_info[:id]) do |user|
        teams = Team.where(path: user_info[:groups])
        organisation = Organisation.find_by(path: user_info[:groups]) || teams.first&.organisation

        raise "No organisation found" unless organisation

        user.email = user_info[:email]
        user.name = user_info[:name]
        user.organisation = organisation
        user.teams = teams
      end

      User.current.access_token = access_token
    rescue RuntimeError
      redirect_to "/403" unless request.path == "/403"
    end
  end

  def current_user
    User.current
  end

  def pundit_user
    User.current
  end

private

  def access_token
    keycloak_token["access_token"]
  end

  def refresh_token
    keycloak_token["refresh_token"]
  end

  def keycloak_token
    JSON cookies.permanent[cookie_name]
  end

  def keycloak_token=(token)
    cookies.permanent[cookie_name] = { value: token, httponly: true }
  end

  def cookie_name
    :"keycloak_token_#{ENV["KEYCLOAK_CLIENT_ID"]}"
  end

  def try_refresh_token
    begin
      self.keycloak_token = KeycloakClient.instance.exchange_refresh_token_for_token(refresh_token)
    rescue StandardError => e
      if e.is_a? Keycloak::KeycloakException
        raise
      else
        false
      end
    end
  end
end
