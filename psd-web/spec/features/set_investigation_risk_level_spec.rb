require "rails_helper"

RSpec.feature "Setting risk level for an investigation", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user, owner: user) }

  scenario "Setting risk level for an investigation" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    # Set risk level for first time
    expect(page).to have_summary_item(key: "Case risk level", value: "Not set")
    page.find("dt", text: "Case risk level", exact_text: true)
        .sibling("dd", class: "govuk-summary-list__actions")
        .click_link "Set"

    expect_to_be_on_set_risk_level_page(case_id: investigation.pretty_id)
    choose "Medium Risk"
    click_button "Set risk level"

    
    expect_confirmation_banner("Risk level set on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "Medium Risk")
    
    # Change risk level
    page.find("dt", text: "Case risk level", exact_text: true)
        .sibling("dd", class: "govuk-summary-list__actions")
        .click_link "Change"

    expect_to_be_on_change_risk_level_page(case_id: investigation.pretty_id)
    choose "High Risk"
    click_button "Set risk level"

    expect_confirmation_banner("Risk level changed on allegation")
    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_summary_item(key: "Case risk level", value: "High Risk")
  end
end
