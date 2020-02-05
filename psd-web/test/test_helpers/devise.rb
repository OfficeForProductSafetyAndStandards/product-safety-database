module TestHelpers
  module Devise
    def sign_in(user = users(:opss), roles: %i[psd_user opss_user])
      allow(KeycloakClient.instance).to receive(:user_account_url).and_return("/account")

      allow(KeycloakClient.instance)
        .to receive(:get_user_roles)
              .with(user.id)
              .and_return(roles)

      stub_omniauth(user)
      visit root_path
      click_on "Sign in to your account"
      user
    end

    def stub_omniauth(user)
      OmniAuth.config.test_mode = true
      groups = user.teams.flat_map(&:path) << user.organisation&.path
      groups.compact!
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
        "provider" => :openid_connect,
        "uid"  => user.id,
        "info" => {
          "email" => user.email,
          "name" => user.name,
        },
        "extra" => {
          "raw_info" => {
            "groups" => groups
          }
        }
      )
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:openid_connect]
    end
  end
end
