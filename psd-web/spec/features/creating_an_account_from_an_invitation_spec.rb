require "rails_helper"
require "support/feature_helpers"

RSpec.feature "Creating an account from an invitation", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config, :with_stubbed_notify, :with_2fa do
  let(:invited_user) { create(:user, :invited, direct_otp: nil) }
  let(:existing_user) { create(:user) }

  scenario "Creating an account from an invitation" do
    visit "/users/#{invited_user.id}/complete-registration?invitation=#{invited_user.invitation_token}"

    expect_to_be_on_complete_registration_page

    fill_in_account_details_with full_name: "Bob Jones", mobile_number: "07731123345", password: "testpassword123@"

    click_button "Continue"

    expect_to_be_on_two_factor_authentication_page

    fill_in "Enter security code", with: invited_user.reload.direct_otp
    click_on "Continue"

    expect_to_be_on_declaration_page
    expect_to_be_signed_in

    # Now sign out and use those credentials to sign back in
    find_link("Sign out", match: :first).click()

    expect_to_be_on_the_homepage

    click_link "Sign in to your account"

    fill_in "Email address", with: invited_user.email
    fill_in "Password", with: "testpassword123@"
    click_on "Continue"

    # Skips 2FA as cookie was set to not require
    # 2FA for 7 days.

    expect_to_be_on_declaration_page
    expect_to_be_signed_in
  end

  scenario "Creating an account from an invitation when signed in as another user", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
    sign_in existing_user

    visit "/users/#{invited_user.id}/complete-registration?invitation=#{invited_user.invitation_token}"

    expect_to_be_on_signed_in_as_another_user_page

    click_button "Create a new account"

    expect_to_be_on_complete_registration_page

    fill_in_account_details_with full_name: "Bob Jones", mobile_number: "07731123345", password: "testpassword123@"

    click_button "Continue"

    expect_to_be_on_two_factor_authentication_page

    fill_in "Enter security code", with: invited_user.reload.direct_otp
    click_on "Continue"

    expect_to_be_on_declaration_page
    expect_to_be_signed_in
  end

  def expect_to_be_on_two_factor_authentication_page
    expect(page).to have_current_path(/^\/two-factor$/)

    expect(page).to have_h1("Check your phone")
  end

  def expect_to_be_on_complete_registration_page
    expect(page).to have_current_path(/\/complete-registration?.+$/)

    expect(page).to have_h1("Create an account")
  end

  def expect_to_be_on_signed_in_as_another_user_page
    expect(page).to have_current_path(/\/complete-registration?.+$/)

    expect(page).to have_h1("You are already signed in to the Product safety database")
  end

  def expect_to_be_on_declaration_page
    expect(page).to have_current_path(/^\/declaration$/)
  end

  def expect_to_be_on_the_homepage
    expect(page).to have_current_path("/")
  end

  def expect_to_be_signed_in
    expect(page).to have_content("Sign out")
  end

  def fill_in_account_details_with(full_name:, mobile_number:, password:)
    fill_in "Full name", with: full_name
    fill_in "Mobile number", with: mobile_number
    fill_in "Password", with: password
  end
end
