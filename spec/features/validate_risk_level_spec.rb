require "rails_helper"

RSpec.feature "Validate risk level", :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:notification) { create(:notification, creator: creator_user) }
  let(:user) { create(:user, :activated) }
  let(:creator_user) { create(:user, :activated) }

  context "when user does not have `risk_level_validator` role" do
    it "does not show the validate button" do
      sign_in user
      visit investigation_path(notification)

      expect(page).not_to have_link "Validate"
    end
  end

  context "when user has `risk_level_validator` role" do
    before do
      AddTeamToNotification.call!(
        user:,
        notification:,
        team: user.team,
        collaboration_class: Collaboration::Access::Edit
      )

      user.roles.create!(name: "risk_level_validator")
      sign_in user
      delivered_emails.clear
    end

    scenario "validate the level" do
      visit investigation_path(notification)

      click_link "Validate"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}/validate-risk-level/edit")

      within_fieldset("Has the notification risk level been validated?") do
        choose "Yes"
      end

      click_on "Continue"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect_confirmation_banner("The notification risk level has been validated")
      expect(page).to have_css(".govuk-summary-list__value", text: "Validated by #{user.team.name} on #{notification.risk_validated_at}")
      expect(page).not_to have_link("Validate")

      click_on "Activity"
      expect(page).to have_content "The notification risk level has been validated"

      expect_email_with_correct_details_to_be_set("has been validated")
    end

    scenario "do not validate the level" do
      visit investigation_path(notification)

      click_link "Validate"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}/validate-risk-level/edit")

      within_fieldset("Has the notification risk level been validated?") do
        choose "No"
      end

      click_on "Continue"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page).not_to have_content("The notification risk level has been validated")
      expect(page).not_to have_content("Validated by #{user.team.name} on #{notification.risk_validated_at}")
      expect(page).to have_link("Validate")

      click_on "Activity"
      expect(page).not_to have_content "The notification risk level has been validated"
    end

    scenario "remove validation" do
      visit("/cases/#{notification.pretty_id}/validate-risk-level/edit")

      within_fieldset("Has the notification risk level been validated?") do
        choose "Yes"
      end

      click_on "Continue"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}")

      validation_link = page.find(:css, "a[href='/cases/#{notification.pretty_id}/validate-risk-level/edit']")
      expect(validation_link.text).to eq "Change"

      validation_link.click

      within_fieldset("Has the notification risk level been validated?") do
        choose "No"
      end

      click_on "Continue"

      expect(page).to have_content("Enter details")

      within_fieldset("Has the notification risk level been validated?") do
        choose "No"
        fill_in "Provide a brief explanation", with: "Mistake made by team member"
      end

      click_on "Continue"

      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page).not_to have_content("The notification risk level has been validated")
      expect(page).not_to have_content("Validated by #{user.team.name} on #{notification.risk_validated_at}")
      expect(page).to have_link("Validate")

      click_on "Activity"
      expect(page).to have_css(".govuk-heading-s", text: "Notification risk level validation removed")
      expect(page).to have_css("p", text: "Mistake made by team member")

      expect_email_with_correct_details_to_be_set("has had validation removed")
    end

    def expect_email_with_correct_details_to_be_set(action)
      delivered_email = delivered_emails.reverse.find { |email| email.recipient == creator_user.team.email }

      expect(delivered_email.recipient).to eq creator_user.team.email
      expect(delivered_email.action_name).to eq "risk_validation_updated"
      expect(delivered_email.personalization).to include(
        name: creator_user.team.name,
        case_title: notification.user_title,
        case_type: "notification",
        case_id: notification.pretty_id,
        updater_name: user.name,
        updater_team_name: user.team.name,
        action:
      )
    end
  end
end
