module LoginHelpers
  module Features
    def sign_in(as_user: build(:user))
      groups = as_user.teams.flat_map(&:path) << as_user.organisation.path

      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:openid_connect] = {
        "provider" => :openid_connect,
        "uid"  => as_user.id,
        "info" => {
          "email" => as_user.email,
          "name" => as_user.name,
        },
        "extra" => {
          "raw_info" => {
            "groups" => groups
          }
        }
      }

      visit user_openid_connect_omniauth_authorize_path
      as_user
    end
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
  config.include LoginHelpers::Features, type: :feature
end
