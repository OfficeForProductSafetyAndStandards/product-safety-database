module LoginHelpers
  def sign_in(as_user: build(:user))
    allow_any_instance_of(ApplicationController).to receive(:access_token).and_return(access_token)
    allow(KeycloakClient.instance).to receive(:user_signed_in?).with(access_token).and_return(true)
    allow(KeycloakClient.instance).to receive(:user_info).and_return(format_user_for_get_userinfo(as_user))
    allow(KeycloakClient.instance).to receive(:get_user_roles).with(as_user.id).and_return(as_user.roles)
  end

  def sign_out
    allow(KeycloakClient.instance).to receive(:user_signed_in?).and_return(false)
  end

  def keycloak_login_url(additional_params = {})
    url_params = {
      response_type: "code",
      client_id: ENV.fetch("KEYCLOAK_CLIENT_ID")
    }.merge(additional_params)

    "#{ENV.fetch('KEYCLOAK_AUTH_URL')}/realms/opss/protocol/openid-connect/auth?#{URI.encode_www_form(url_params)}"
  end

private

  def format_user_for_get_userinfo(user)
    { id: user.id, email: user.email, name: user.name, groups: ([user.organisation&.path] + user.teams.map(&:path)).compact }
  end

  def access_token
    "test"
  end
end

RSpec.configure do |config|
  config.include LoginHelpers
end
