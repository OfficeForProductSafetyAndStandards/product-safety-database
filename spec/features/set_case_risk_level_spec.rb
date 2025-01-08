require "rails_helper"

RSpec.feature "Setting risk level for an investigation", :with_stubbed_antivirus, :with_stubbed_mailer do
  let!(:investigation) { create(:allegation, edit_access_teams: [team_with_access]) }

  let!(:investigation_with_serious_risk_assessment) do
    create(:allegation, edit_access_teams: [team_with_access], risk_assessments: [
      create(:risk_assessment, risk_level: "serious")
    ])
  end

  let!(:investigation_with_multiple_risk_assessments) do
    create(:allegation, edit_access_teams: [team_with_access], risk_assessments: [
      create(:risk_assessment, risk_level: "serious"),
      create(:risk_assessment, risk_level: "high"),
      create(:risk_assessment, risk_level: "not_conclusive")
    ])
  end

  let(:creator_team) { investigation.creator_user.team }
  let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }

  before do
    sign_in(user)
    delivered_emails.clear
  end

  context "when the user does not belong to a team with edit access in the investigation" do
    let(:user) { create(:user, :activated, has_viewed_introduction: true, team: create(:team, name: "Team without access")) }

    scenario "they cannot set the risk level for the notification" do
      visit "/cases/#{investigation.pretty_id}"
      expect(page).not_to have_link("Set risk level")
    end
  end

  scenario "Setting risk level for an investigation with no risk assessments added" do
    visit "/cases/#{investigation.pretty_id}"

    # Set risk level for first time
    expect(page).to have_summary_item(key: "Notification risk level", value: "Not set")
    click_set_risk_level_link

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs
    choose "Serious risk"

    expect(page).to have_text("This notification does not have a risk assessment. You may want to add a risk assessment before setting the notification risk level.")

    click_button "Save"

    expect_confirmation_banner("The notification risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Notification risk level", value: "Serious risk")
    expect(page).to have_css("span.opss-tag--risk1", text: "Serious risk")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Notification risk level set to serious risk")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "set to serious risk",
    )
  end

  scenario "Setting risk level on a notification with an existing 'serious' risk assessment" do
    visit "/cases/#{investigation_with_serious_risk_assessment.pretty_id}/edit-risk-level"

    expect(page).to have_content("This notification has 1 risk assessment added, assessing the risk as serious risk.")
  end

  scenario "Setting risk level on a notification with multiple risk assessments" do
    visit "/cases/#{investigation_with_multiple_risk_assessments.pretty_id}/edit-risk-level"

    expect(page).to have_content("This notification has 3 risk assessments added, assessing the risk as serious risk, high risk and not conclusive.")
  end

  scenario "Changing risk level for an investigation" do
    investigation.update!(risk_level: :medium)
    visit "/cases/#{investigation.pretty_id}"

    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Medium risk")
    expect_to_have_notification_breadcrumbs
    choose("Not conclusive")
    click_button "Save"

    expect_confirmation_banner("The notification risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Notification risk level", value: "Not conclusive")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Notification risk level changed to not conclusive")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "changed to not conclusive",
    )

    # Changing the risk level back to a default one
    within('nav[aria-label="Secondary"]') { click_link "Notification" }
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Not conclusive")
    expect_to_have_notification_breadcrumbs
    choose("High risk")
    click_button "Save"

    expect_confirmation_banner("The notification risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Notification risk level", value: "High risk")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Notification risk level changed to high risk")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "changed to high risk",
    )
  end

  def click_change_risk_level_link
    click_link "Change the risk level"
  end

  def click_set_risk_level_link
    click_link "Change the risk level"
  end
end
