require "rails_helper"

RSpec.feature "Sign in", :with_elasticsearch, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_accepted_declaration: true) }

  it "allows user to sign in" do
    visit root_path
    click_on "Sign in to your account"

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_on "Continue"

    expect(page).to have_css("h2")
    expect(page).to have_link("Your cases")
    expect(page).to have_link("All cases")
    expect(page).to have_link("More information")

    # click_on "Sign out", match: :first
    # click_on "Sign in to your account"
    # click_on "Forgot your password?"

    # fill_in "user[email]", with: user.email
    # click_on "Send email"
    # expect(page).to have_css("p.govuk-body", text: "Click the link in the email to reset your password.")

    # visit root_path

    # click_on "Sign in to your account"

    # fill_in "user[email]", with: user.email
    # fill_in "user[password]", with: "new_password"
    # click_on "Continue"

    # expect(page).to have_css("h2")
    # expect(page).to have_link("Your cases")
    # expect(page).to have_link("All cases")
    # expect(page).to have_link("More information")
  end
end
