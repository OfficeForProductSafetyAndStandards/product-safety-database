require "rails_helper"

RSpec.feature "Adding a risk assessment to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do

  let(:risk_assessment_file) { Rails.root + "test/fixtures/files/new_risk_assessment.txt" }
  let(:team) { create(:team, name: "MyCouncil Trading Standards") }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team) }

  let(:product1) { create(:product_washing_machine, name: "MyBrand washing machine model X") }
  let(:product2) { create(:product_washing_machine, name: "MyBrand washing machine model Y") }

  let(:investigation) { create(:allegation, products: [product1, product2], creator: user) }

  scenario "Adding a risk assessment to a case with a multiple products (with validation errors)" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add new"
    expect_to_be_on_add_supporting_information_page

    choose "Risk assessment"
    click_button "Continue"

    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation.pretty_id)
    click_button "Add risk assessment"

    expect(page).to have_text("Enter the date of the assessment")
    expect(page).to have_text("Select the risk level")
    expect(page).to have_text("Select who completed the assessment")
    expect(page).to have_text("You must choose at least one product")
    expect(page).to have_text("You must upload the risk assessment")

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "Me or my team"
    end

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    attach_file "Upload the risk assessment", risk_assessment_file

    fill_in("Further details (optional)", with: "Products risk-assessed in response to incident.")

    click_button "Add risk assessment"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Date of assessment",  value: "3 April 2020")
    expect(page).to have_summary_item(key: "Risk level",          value: "Serious risk")
    expect(page).to have_summary_item(key: "Assessed by",         value: "MyCouncil Trading Standards")
    expect(page).to have_summary_item(key: "Product assessed",    value: "MyBrand washing machine model X")

    expect(page).to have_text("old_risk_assessment.txt")
    expect(page).to have_text("Products risk-assessed in response to incident.")
  end

end
