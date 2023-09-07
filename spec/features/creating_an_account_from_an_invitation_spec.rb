require "rails_helper"
require "support/feature_helpers"

RSpec.feature "Creating an account from an invitation", :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, :with_2fa do
  let(:invited_user) { create(:user, :invited, direct_otp: nil) }
  let(:existing_user) { create(:user) }

  scenario "Creating an account from an invitation" do
    visit "/users/#{invited_user.id}/complete-registration?invitation=#{invited_user.invitation_token}"

    expect_to_be_on_complete_registration_page

    click_button "Continue"

    expect_ordered_error_list

    fill_in_account_details_with full_name: "Bob Jones", mobile_number: "07731123345", password: "testpassword123@"

    click_button "Continue"

    expect_to_be_on_secondary_authentication_page

    fill_in "Enter security code", with: otp_code
    click_on "Continue"

    expect_to_be_on_declaration_page
    expect_to_be_signed_in

    # Now sign out and use those credentials to sign back in
    find_link("Sign out", match: :first).click

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

  scenario "Creating an account from an invitation when signed in as another user", :with_stubbed_antivirus, :with_stubbed_mailer do
    sign_in existing_user

    visit "/users/#{invited_user.id}/complete-registration?invitation=#{invited_user.invitation_token}"

    expect_to_be_on_signed_in_as_another_user_page

    click_button "Create a new account"

    expect_to_be_on_complete_registration_page

    click_button "Continue"

    expect_ordered_error_list

    fill_in_account_details_with full_name: "Bob Jones", mobile_number: "07731123345", password: "testpassword123@"

    click_button "Continue"

    expect_to_be_on_secondary_authentication_page

    fill_in "Enter security code", with: otp_code
    click_on "Continue"

    expect_to_be_on_declaration_page
    expect_to_be_signed_in
  end

  context "when a previous registration was abandoned before verifying mobile number" do
    let(:invited_user) do
      create(
        :user,
        :invited,
        name: "Bob Jones",
        mobile_number: "07700 900 982",
        mobile_number_verified: false
      )
    end

    scenario "it shouldn’t show values entered previously" do
      visit "/users/#{invited_user.id}/complete-registration?invitation=#{invited_user.invitation_token}"

      expect_to_be_on_complete_registration_page

      # Form should NOT contain values from previous abandoned registration
      expect(find_field("Mobile number").value).to eq ""

      # Deliberately leave password blank
      fill_in_account_details_with full_name: "Bob Jones", mobile_number: "07731123345", password: ""

      click_button "Continue"

      # Form SHOULD now contain pre-filled values from previous submission
      expect(find_field("Full name").value).to eq("Bob Jones")
      expect(find_field("Mobile number").value).to eq("07731123345")

      # Now add a password
      fill_in "Password", with: "testpassword123@"

      click_button "Continue"

      expect_to_be_on_secondary_authentication_page

      fill_in "Enter security code", with: otp_code
      click_on "Continue"

      expect_to_be_on_declaration_page
      expect_to_be_signed_in
    end
  end

  def expect_to_be_signed_in
    expect(page).to have_content("Sign out")
  end

  def fill_in_account_details_with(full_name:, mobile_number:, password:)
    fill_in "Full name", with: full_name
    fill_in "Mobile number", with: mobile_number
    fill_in "Password", with: password
  end

  def otp_code
    invited_user.reload.direct_otp
  end

  def expect_ordered_error_list
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter your full name"
    expect(errors_list[1].text).to eq "Enter your mobile number"
    expect(errors_list[2].text).to eq "Enter a password"
  end
end
