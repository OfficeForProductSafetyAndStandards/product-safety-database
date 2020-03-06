module LoginHelpers
  def sign_in(user = create(:user, :activated, has_viewed_introduction: true))
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "2538fhdkvuULE36f"
    click_on "Continue"
  end

  def sign_out
    return if page.has_css?("a", text: "Sign in to your account")

    click_on "Sign out", match: :first
  end
end

module Devise::Test::TokenGenerator
  def stubbed_devise_generated_token(reset_token = Devise.token_generator.generate(User, :reset_password_token))
    allow(Devise.token_generator)
      .to receive(:generate)
      .with(User, :reset_password_token).and_return(reset_token)

    reset_token
  end
end

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers
  config.include LoginHelpers, type: :feature
  config.include Devise::Test::TokenGenerator
end
