require "rails_helper"

RSpec.feature "Registration process", :with_stubbed_mailer, :with_stubbed_notify do
  let(:team) { create(:team) }
  let(:admin) { create(:user, :team_admin, has_accepted_declaration: true, has_viewed_introduction: true, team: team) }
  let(:invitee_email) { Faker::Internet.safe_email }

  before do
    set_whitelisting_enabled(false)
    allow(Rails.application.config)
      .to receive(:secondary_authentication_enabled).and_return(true)
  end

  it "sending an invitation and registering after changing the phone number" do
    sign_in(admin)

    visit "/teams/#{team.id}/invitations/new"

    expect(page).to have_title("Invite a team member")

    wait_time = SecondaryAuthentication::TIMEOUTS[SecondaryAuthentication::INVITE_USER] + 1
    travel_to(Time.now.utc + wait_time.seconds) do
      visit "/teams/#{team.id}/invitations/new"

      enter_secondary_authentication_code(admin.reload.direct_otp)

      invite_user_to_team

      expect_user_invited_successfully

      sign_out

      invitee = User.find_by!(email: invitee_email)

      visit "/users/#{invitee.id}/complete-registration?invitation=#{invitee.invitation_token}"
      fill_in_registration_form

      expect_to_be_on_secondary_authentication_page

      click_link "Not received a text message?"

      expect_to_be_on_resend_secondary_authentication_page
      find("details summary", text: "Change where the text message is sent").click
      fill_in "Mobile number", with: "70123456789"

      click_button "Resend security code"
      expect_to_be_on_secondary_authentication_page
      enter_secondary_authentication_code(invitee.reload.direct_otp)

      expect_to_be_on_declaration_page
      check "I agree"
      click_button "Continue"
      click_link "Skip introduction"
      click_link("Your account", match: :first)

      expect(page).to have_h1("Your account")
      expect(page).to have_summary_item(key: "Mobile number", value: "70123456789")
    end
  end

  def invite_user_to_team
    fill_in "Email address", with: invitee_email
    click_on "Send invitation email"
  end

  def expect_user_invited_successfully
    expect(page).to have_title(team.display_name)
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{invitee_email}\")")
  end

  def fill_in_registration_form
    fill_in "Full name",     with: Faker::Movies::Lebowski.character
    fill_in "Mobile number", with: "71234567890"
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
