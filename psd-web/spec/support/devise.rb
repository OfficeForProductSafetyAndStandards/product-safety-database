module LoginHelpers
  def sign_in(user = create(:user, :activated, has_viewed_introduction: true))
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_on "Continue"
  end
end

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers
  config.include LoginHelpers, type: :feature
end
