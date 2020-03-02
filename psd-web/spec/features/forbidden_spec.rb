require "rails_helper"

RSpec.describe "Access forbidden", :with_stubbed_keycloak_config, type: :feature do
  it "Logging in when user does not yet exist and has no groups" do
    sign_in(as_user: build(:user, organisation: nil))
    expect(page).to have_text("You don’t have permission to see this page")
  end
end
