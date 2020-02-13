require "rails_helper"

RSpec.feature "Access forbidden", :with_stubbed_keycloak_config do
  let(:user) { create(:user) }
  before do
    user.organisation = nil
    user.save(validate: false)
  end

  scenario "Logging in when user does not yet exist and has no groups" do
    sign_in(user)
    expect(page).to have_text("You don’t have permission to see this page")
    expect(page).to have_link("Sign in to your account", href: new_user_session_path)
  end
end
