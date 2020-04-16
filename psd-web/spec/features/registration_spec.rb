require "rails_helper"

RSpec.feature "Registration process", :with_stubbed_mailer, :with_stubbed_notify do
  let(:team) { create(:team) }
  let(:admin) { create(:user, :team_admin, has_accepted_declaration: true, has_viewed_introduction: true, teams: [team]) }
  let(:invitee_email) { Faker::Internet.safe_email }

  before do
    allow(Rails.application.config)
      .to receive(:email_whitelist_enabled).and_return(false)
    allow(Rails.application.config)
      .to receive(:two_factor_authentication_enabled).and_return(true)
  end

  it "sending an invitation and registering" do
    sign_in(admin)

    visit "/teams/#{team.id}/invite"

    enter_two_factor_authentication_code(otp_code)

    invite_user_to_team

    expect_user_invited_successfully

    sign_out

    invitee = User.find_by!(email: invitee_email)

    visit "/users/#{invitee.id}/complete-registration?invitation=#{invitee.invitation_token}"
    fill_in_registration_form

    expect_to_be_on_two_factor_authentication_page

    enter_two_factor_authentication_code(otp_code)

    expect_to_be_on_declaration_page
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

  def expect_to_be_on_two_factor_authentication_page
    expect(page).to have_title("Check your phone")
  end

  def enter_two_factor_authentication_code(otp_code)
    fill_in "Enter security code", with: otp_code
    click_on "Continue"
  end

  def expect_to_be_on_declaration_page
    expect(page).to have_title("Declaration - Product safety database - GOV.UK")
  end

  def otp_code
    SecondaryAuthentication.last.direct_otp
  end
end
