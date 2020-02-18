require "rails_helper"

RSpec.feature "Help pages", :with_stubbed_keycloak_config do
  scenario "User signed out" do
    sign_out(:user)

    visit "/help/about"
    expect(page).to have_text("How to use the Product safety database")
    expect(page).to have_link("Sign in")

    visit "/help/privacy-notice"
    expect(page).to have_text("Privacy Notice - Product safety database")
    expect(page).to have_link("Sign in")

    visit "/help/terms-and-conditions"
    expect(page).to have_text("Product safety database Terms of Use")
    expect(page).to have_link("Sign in")
  end
end
