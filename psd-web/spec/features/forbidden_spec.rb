require "rails_helper"

RSpec.feature "Access forbidden", :with_stubbed_keycloak_config do
  scenario "Logging in when user does not yet exist and has no groups" do
    sign_in(as_user: build(:user, organisation: nil))
    expect(page).to have_text("You don’t have permission to see this page")
    visit "/cases"
    expect(page).to have_link("Sign in to your account", href: user_openid_connect_omniauth_authorize_path)
  end
end
