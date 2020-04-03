require "rails_helper"

RSpec.feature "Admin Panel", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:password) { user.password }

  def fill_in_credentials(password_override: nil)
    fill_in "Email address", with: user.email
    if password_override
      fill_in "Password", with: password_override
    else
      fill_in "Password", with: password
    end
    click_on "Continue"
  end

  context "when user tries to access admin", :with_2fa do
    scenario "needs to be signed in as superadmin" do
      visit "/admin"
      expect(page).to have_css("h1", text: "Sign in")
      fill_in_credentials
      expect(page).to have_css("h1", text: "Check your phone")
      visit "/admin"
      expect(page).to have_css("h1", text: "Check your phone")

      fill_in "Enter security code", with: user.reload.direct_otp
      click_on "Continue"

      visit "/admin"
      expect(page).to have_css("h2", text: "Your cases")

      user.user_roles.create(name: "superadmin")

      visit "/admin"
      expect(page).to have_css("h1", text: "Site Administration")
    end
  end
end
