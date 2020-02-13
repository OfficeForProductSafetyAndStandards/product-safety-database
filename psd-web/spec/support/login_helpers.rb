module LoginHelpers
  module Features
    def sign_in(as_user: create(:user, :activated, has_viewed_introduction: true))
      groups = as_user.teams.flat_map(&:path) << as_user.organisation&.path
      groups.compact!

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

      visit root_path
      click_on "Sign in to your account"
      as_user
    end
  end
end

RSpec.configure do |config|
  config.include LoginHelpers::Features, type: :feature
  config.before do
    OmniAuth.config.test_mode = true
  end
end
