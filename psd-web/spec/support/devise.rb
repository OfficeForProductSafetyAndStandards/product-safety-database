module LoginHelpers
  def sign_in(user = create(:user, :activated, has_viewed_introduction: true))
    visit new_user_session_path

    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms").and_return(body: {}.to_json)

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_on "Continue"

    fill_in "Enter security code", with: user.reload.direct_otp
    click_on "Continue"
  end

  def sign_out
    return if page.has_css?("a", text: "Sign in to your account")

    click_on "Sign out", match: :first
  end

end

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers
  config.include LoginHelpers, type: :feature
  config.before(:each, :with_stubbed_2fa) do
    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms").and_return(body: {}.to_json, status: 200)
  end
end
