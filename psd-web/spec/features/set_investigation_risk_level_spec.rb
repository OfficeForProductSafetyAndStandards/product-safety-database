require "rails_helper"

RSpec.feature "Setting risk level for an investigation", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:investigation) { create(:allegation) }
  let(:creator_team) { investigation.creator_user.team }
  let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }

  before do
    AddTeamToAnInvestigation.call!(current_user: user, investigation: investigation, collaborator_id: team_with_access.id, include_message: false)
    sign_in(user)
    delivered_emails.clear
  end

  context "when the user does not belong to a team with edit access in the investigation" do
    let(:user) { create(:user, :activated, has_viewed_introduction: true, team: create(:team, name: "Team without access")) }

    scenario "they cannot set the risk level for the case" do
      visit "/cases/#{investigation.pretty_id}"
      expect(risk_level_actions_in_overview).not_to have_link(text: "Set")
    end
  end

  scenario "Setting risk level for an investigation" do
    visit "/cases/#{investigation.pretty_id}"

    # Set risk level for first time
    expect(page).to have_summary_item(key: "Case risk level", value: "Not set")
    click_set_risk_level_link

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    choose "Medium risk"
    click_button "Set risk level"

    expect_confirmation_banner("Case risk level set to medium risk")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Medium risk")

    # Risk level change reflected in audit activity log
    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Case risk level set to medium risk")

    # Teams/users with access receive an email with the update
    email = delivered_emails.last
    expect(email.recipient).to eq creator_team.team_recipient_email
    expect(email.personalization).to include(
      name: creator_team.name,
      verb_with_level: "set to medium risk",
    )
  end

  scenario "Changing risk level for an investigation" do
    investigation.update!(risk_level: "Medium risk")
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
    fill_in "Other risk level", with: "Mildly risky"
    click_button "Set risk level"

    expect_confirmation_banner("Case risk level changed to mildly risky")
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

    # Selecting Other and introducing a level that matches one of the other options
    # will result in the other option being pre-selected when changing risk level
    # in the future
    click_link "Overview"
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Other")
    fill_in "Other risk level", with: "Low risk"
    click_button "Set risk level"

    expect_confirmation_banner("Case risk level changed to low risk")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Low risk")

    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(find_field("Low risk")).to be_checked
  end

  def risk_level_actions_in_overview
    page.find("dt", text: "Case risk level", exact_text: true)
        .sibling("dd", class: "govuk-summary-list__actions")
  end

  def click_change_risk_level_link
    risk_level_actions_in_overview.click_link "Change"
  end

  def click_set_risk_level_link
    risk_level_actions_in_overview.click_link "Set"
  end
end
