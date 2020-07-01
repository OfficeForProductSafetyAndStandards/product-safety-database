require "rails_helper"

RSpec.feature "Setting risk level for an investigation", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user, owner_user: user) }

  before do
    sign_in(user)
  end

  scenario "Setting risk level for an investigation" do
    visit "/cases/#{investigation.pretty_id}"

    # Set risk level for first time
    expect(page).to have_summary_item(key: "Case risk level", value: "Not set")
    click_set_risk_level_link

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    choose "Medium Risk"
    click_button "Set risk level"

    expect_confirmation_banner("Risk level set on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Medium Risk")
  end

  scenario "Changing risk level for an investigation" do
    investigation.update!(risk_level: "Medium Risk")
    visit "/cases/#{investigation.pretty_id}"

    # Change risk level to a custom one
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(find_field("Medium Risk")).to be_checked
    choose "Other"
    fill_in "Other risk level", with: "Mildly risky"
    click_button "Set risk level"

    expect_confirmation_banner("Risk level changed on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Mildly risky")

    # Selecting Other and leaving the input field empty sets the risk level as unset
    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Other")
    expect(page).to have_field("Other risk level", with: "Mildly risky")
    fill_in "Other risk level", with: ""
    click_button "Set risk level"

    expect_confirmation_banner("Risk level changed on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Not set")

    # Selecting Other and introducing a level that matches one of the other options
    # will result in the other option being pre-selected when changing risk level
    # in the future
    click_set_risk_level_link

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    expect(page).to have_checked_field("Not set")
    choose "Other"
    fill_in "Other risk level", with: "Low Risk"
    click_button "Set risk level"

    expect_confirmation_banner("Risk level set on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Low Risk")

    click_change_risk_level_link

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    expect(find_field("Low Risk")).to be_checked
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
