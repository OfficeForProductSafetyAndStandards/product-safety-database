require "rails_helper"

RSpec.feature "Redirecting after 2fa", :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_opensearch do
  let(:team) { create(:team) }
  let(:admin) { create(:user, :team_admin, has_accepted_declaration: true, has_viewed_introduction: true, team:) }
  let(:invitee_email) { Faker::Internet.email }

  before do
    set_whitelisting_enabled(false)
    allow(Rails.application.config)
      .to receive(:secondary_authentication_enabled).and_return(true)
  end

  context "when making a GET request" do
    it "redirects user to the page they were trying to access" do
      sign_in(admin)
      visit "/"

      wait_time = SecondaryAuthentication::TIMEOUTS[SecondaryAuthentication::INVITE_USER] + 1
      travel_to(Time.zone.now.utc + wait_time.seconds) do
        visit "/teams/#{team.id}/invitations/new"
        enter_secondary_authentication_code(admin.reload.direct_otp)
        visit "/teams/#{team.id}/invitations/new"
        expect(page).not_to have_content "Request could not be completed. Please try again."
      end
    end
  end

  context "when user was previously on the 2fa page" do
    it "logs in without showing error message" do
      sign_in_but_do_not_complete_2fa(admin)

      wait_time = SecondaryAuthentication::TIMEOUTS[SecondaryAuthentication::INVITE_USER] + 1
      travel_to(Time.zone.now.utc + wait_time.seconds) do
        click_link "Not received a text message?"
        click_button "Resend security code"
        enter_secondary_authentication_code(admin.reload.direct_otp)

        expect(page).not_to have_content "Request could not be completed. Please try again."
      end
    end
  end

  context "when making a different request" do
    it "redirects user back to the last page they were on" do
      sign_in(admin)
      visit "/teams/#{team.id}/invitations/new"

      wait_time = SecondaryAuthentication::TIMEOUTS[SecondaryAuthentication::INVITE_USER] + 1
      travel_to(Time.zone.now.utc + wait_time.seconds) do
        invite_user_to_team
        enter_secondary_authentication_code(admin.reload.direct_otp)

        expect(page).to have_current_path("/teams/#{team.id}/invitations/new")
        expect(page).to have_content "Request could not be completed. Please try again."
      end
    end
  end

  def invite_user_to_team
    fill_in "Email address", with: invitee_email
    click_on "Send invitation email"
  end

  def enter_secondary_authentication_code(otp_code)
    fill_in "Enter security code", with: otp_code
    click_on "Continue"
  end

  def otp_code
    user.reload.direct_otp
  end
end
