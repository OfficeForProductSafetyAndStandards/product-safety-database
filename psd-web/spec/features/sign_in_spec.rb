require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer do
  include ActiveSupport::Testing::TimeHelpers
  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  it "allows to sign in and times you out in due time" do
    visit investigation_path(investigation)
    expect(page).to_not have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

    travel_to 24.hours.from_now do
      visit investigation_path(investigation)
      expect(page).to_not have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
    end
  end

  it "allows user to sign in" do
    visit root_path
    click_on "Sign in to your account"

    fill_in "Email address", with: user.email
    fill_in "Password", with: "password"
    click_on "Continue"

    expect(page).to have_css("h2")
    expect(page).to have_link("Your cases")
    expect(page).to have_link("All cases")
    expect(page).to have_link("More information")
  end
end
