require "rails_helper"

RSpec.feature "Registration process", :with_stubbed_mailer, :with_stubbed_notify do
  let(:team) { create(:team) }
  let(:admin) { create(:user, :team_admin, has_accepted_declaration: true, has_viewed_introduction: true, team:) }
  let(:invitee_email) { Faker::Internet.email }
  let(:name) { "Bill Smith" }

  before do
    set_whitelisting_enabled(false)
    allow(Rails.application.config)
      .to receive(:secondary_authentication_enabled).and_return(true)

    sign_in(admin)
    visit "/teams/#{team.id}/invitations/new"
  end

  context "when a previously deleted user is invited back" do
    let!(:deleted_user) { create(:user, :deleted, team:) }

    it "allows deleted user to sign up again" do
      invite_user_to_team(deleted_user.email)
      expect_user_invited_successfully(deleted_user.email)
      sign_out

      invitee = User.find_by!(email: deleted_user.email)
      visit "/users/#{invitee.id}/complete-registration?invitation=#{invitee.invitation_token}"
      fill_in_registration_form
      expect_to_be_on_secondary_authentication_page

      click_link "Not received a text message?"
      expect_to_be_on_resend_secondary_authentication_page
      find("details summary", text: "Change where the text message is sent").click
      fill_in "Mobile number", with: "07012345678"

      click_button "Resend security code"
      expect_to_be_on_secondary_authentication_page
      enter_secondary_authentication_code(invitee.reload.direct_otp)

      expect_to_be_on_declaration_page
      check "I agree"
      click_button "Continue"
      click_link "Skip introduction"
      click_link("Your account", match: :first)

      expect(page).to have_h1("Your account")
      expect(page).to have_summary_item(key: "Mobile number", value: "07012345678")
    end
  end

  it "sending an invitation and registering after changing the phone number" do
    expect(page).to have_title("Invite a team member")

    wait_time = SecondaryAuthentication::TIMEOUTS[SecondaryAuthentication::INVITE_USER] + 1
    travel_to(Time.zone.now.utc + wait_time.seconds) do
      visit "/teams/#{team.id}/invitations/new"
      enter_secondary_authentication_code(admin.reload.direct_otp)
      invite_user_to_team
      expect_user_invited_successfully
      sign_out

      invitee = User.find_by!(email: invitee_email)
      visit "/users/#{invitee.id}/complete-registration?invitation=#{invitee.invitation_token}"
      expect(page).to have_field("Full name", with: name)
      fill_in_registration_form
      expect_to_be_on_secondary_authentication_page

      click_link "Not received a text message?"
      expect_to_be_on_resend_secondary_authentication_page
      find("details summary", text: "Change where the text message is sent").click
      fill_in "Mobile number", with: "07012345678"

      click_button "Resend security code"
      expect_to_be_on_secondary_authentication_page
      enter_secondary_authentication_code(invitee.reload.direct_otp)

      expect_to_be_on_declaration_page
      check "I agree"
      click_button "Continue"
      click_link "Skip introduction"
      click_link("Your account", match: :first)

      expect(page).to have_h1("Your account")
      expect(page).to have_summary_item(key: "Mobile number", value: "07012345678")
    end
  end

  def invite_user_to_team(email = invitee_email)
    fill_in "Email address", with: email
    fill_in "Full name", with: name
    click_on "Send invitation email"
  end

  def expect_user_invited_successfully(email = invitee_email)
    expect(page).to have_title(team.display_name)
    expect(page).to have_link(email)
  end

  def fill_in_registration_form
    fill_in "Full name",     with: Faker::Movies::Lebowski.character
    fill_in "Mobile number", with: "07123456789"
    fill_in "Password",      with: "testpassword"
    click_on "Continue"
  end

  def enter_secondary_authentication_code(otp_code)
    fill_in "Enter security code", with: otp_code
    click_on "Continue"
  end

  def otp_code
    user.reload.direct_otp
  end
end
