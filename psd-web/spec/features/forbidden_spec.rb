require "rails_helper"

RSpec.feature "Access forbidden", :with_keycloak_config do
  scenario "Logging in when user does not yet exist and has no groups" do
    sign_in(as_user: build(:user, organisation: nil))
    visit "/cases"
    expect(page).to have_text("You don't have permission to see that page")
  end
end
