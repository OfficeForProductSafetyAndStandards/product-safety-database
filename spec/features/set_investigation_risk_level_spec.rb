require "rails_helper"

RSpec.feature "Setting risk level for an investigation", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
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
      create(:risk_assessment, risk_level: "other", custom_risk_level: "urgent")
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

    scenario "they cannot set the risk level for the case" do
      visit "/cases/#{investigation.pretty_id}"
      expect(page).not_to have_link("Set risk level")
    end
  end

  scenario "Setting risk level for an investigation with no risk assessments added" do
    visit "/cases/#{investigation.pretty_id}"

    # Set risk level for first time
    expect(page).to have_summary_item(key: "Case risk level", value: "Not set")
    click_set_risk_level_link

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    choose "Serious risk"

    expect(page).to have_text("This case does not have a risk assessment. You may want to add a risk assessment before setting the case risk level.")

    click_button "Set risk level"

    expect_confirmation_banner("The case risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Serious risk")
    expect(page).to have_css("span.opss-tag--risk1", text: "Serious risk")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Case risk level set to serious risk")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "set to serious risk",
    )
  end

  scenario "Setting risk level on a case with an existing 'serious' risk assessment" do
    visit "/cases/#{investigation_with_serious_risk_assessment.pretty_id}/edit-risk-level"

    expect(page).to have_content("This case has 1 risk assessment added, assessing the risk as serious risk.")
  end

  scenario "Setting risk level on a case with multiple risk assessments" do
    visit "/cases/#{investigation_with_multiple_risk_assessments.pretty_id}/edit-risk-level"

    expect(page).to have_content("This case has 3 risk assessments added, assessing the risk as serious risk, high risk and urgent.")
  end

  scenario "Changing risk level for an investigation" do
    investigation.update!(risk_level: :medium)
    visit "/cases/#{investigation.pretty_id}"

    # Selecting Other and leaving the input field empty causes a validation error
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Medium risk")
    choose("Other")
    click_button "Set risk level"

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_error("Set a risk level")
    expect(page).to have_checked_field("Other")

    # Fill the field with a custom risk level
    fill_in "Custom risk level", with: "Mildly risky"
    click_button "Set risk level"

    expect_confirmation_banner("The case risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Mildly risky")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Case risk level changed to mildly risky")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "changed to mildly risky",
    )

    # Changing the risk level back to a default one
    within('nav[aria-label="Secondary"]') { click_link "Case" }
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Other")
    choose("High risk")
    click_button "Set risk level"

    expect_confirmation_banner("The case risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "High risk")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Case risk level changed to high risk")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "changed to high risk",
    )

    # Selecting Other and introducing a level that matches one of the other options
    # will result in the other option being pre-selected when changing risk level
    # in the future
    within('nav[aria-label="Secondary"]') { click_link "Case" }
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("High risk")
    choose("Other")
    fill_in "Custom risk level", with: "Low"
    click_button "Set risk level"

    expect_confirmation_banner("The case risk level was updated")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Low risk")

    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(find_field("Low risk")).to be_checked
  end

  def click_change_risk_level_link
    click_link "Change the risk level"
  end

  def click_set_risk_level_link
    click_link "Change the risk level"
  end
end
