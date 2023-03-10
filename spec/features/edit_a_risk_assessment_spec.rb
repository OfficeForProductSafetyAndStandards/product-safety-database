require "rails_helper"

RSpec.feature "Editing a risk assessment on a case", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:risk_assessment_file_path) { Rails.root.join "test/fixtures/files/new_risk_assessment.txt" }
  let(:risk_assessment_file) { Rack::Test::UploadedFile.new(risk_assessment_file_path) }
  let(:user) { create(:user, :activated, name: "Joe Bloggs") }

  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }

  let!(:doll_investigation_product) { create(:investigation_product, investigation:, product: doll) } # rubocop:disable RSpec/LetSetup
  let!(:teddy_bear_investigation_product) { create(:investigation_product, investigation:, product: teddy_bear) }

  let(:investigation) do
    create(:allegation,
           creator: user,
           risk_level: :serious)
  end

  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:risk_assessment) do
    create(:risk_assessment,
           investigation:,
           assessed_on: Date.parse("2020-01-02"),
           assessed_by_team: team,
           risk_level: :serious,
           investigation_products: [teddy_bear_investigation_product],
           risk_assessment_file:)
  end

  scenario "Editing a risk assessment (with validation errors)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (1)"
    click_link "Serious risk: Teddy Bear"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    click_link "Edit risk assessment"

    expect_to_be_on_edit_risk_assessement_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    # Expect page to be pre-filled with existing values
    within_fieldset("Date of assessment") do
      expect(page).to have_field("Day", with: "2")
      expect(page).to have_field("Month", with: "1")
      expect(page).to have_field("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      expect(page).to have_checked_field("Serious risk")
    end

    within_fieldset("Who completed the assessment?") do
      expect(page).to have_checked_field("Another team or market surveilance authority")

      expect(page).to have_select("Choose team", selected: "MyCouncil Trading Standards")
    end

    within_fieldset("Which products were assessed?") do
      expect(page).to have_checked_field("Teddy Bear")
      expect(page).to have_unchecked_field("Doll")
    end

    expect(page).to have_text("new_risk_assessment.txt")

    # Update the date assessed to test activity rendering
    within_fieldset("Date of assessment") do
      fill_in "Day", with: "10"
      fill_in "Month", with: "2"
    end

    # Update some of the fields to include a validation error
    within_fieldset("What was the risk level?") do
      choose "Other"
    end

    within_fieldset("Who completed the assessment?") do
      choose "Someone else"
    end

    within_fieldset("Which products were assessed?") do
      uncheck "Teddy Bear"
    end

    within_fieldset("Upload the risk assessment") do
      find("span", text: "Replace this file").click
      attach_file "Select file", risk_assessment_file_path
    end

    click_button "Update risk assessment"

    # Validation errors
    expect(page).to have_text("Enter other risk level")
    expect(page).to have_text("You must choose at least one product")
    expect(page).to have_text("Enter organisation name")

    # Fix validation errors
    within_fieldset("What was the risk level?") do
      choose "Other"
      fill_in "Other", with: "Medium-high risk"
    end

    within_fieldset("Who completed the assessment?") do
      fill_in "Organisation name", with: "RiskAssessmentsRUs"
    end

    within_fieldset("Which products were assessed?") do
      check "Doll"
    end

    click_button "Update risk assessment"

    expect_to_be_on_update_case_risk_level_from_risk_assessment_page(case_id: investigation.pretty_id)

    expect(page).to have_content("The risk assessment says the level of risk is medium-high risk.")

    within_fieldset("Would you like to match the case risk level to the risk assessment level?") do
      choose("Yes, set the case risk level to medium-high risk")
    end

    click_button "Set risk level"

    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)

    click_link "Medium-high risk: Doll"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    expect(page).to have_summary_item(key: "Risk level",          value: "Medium-high risk")
    expect(page).to have_summary_item(key: "Assessed by",         value: "RiskAssessmentsRUs")
    expect(page).to have_summary_item(key: "Product assessed",    value: "Doll (#{doll.psd_ref})")

    click_link "Back to allegation"
    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_content("Risk assessment edited")
    expect(page).to have_content("Edited by Joe Bloggs")
    expect(page).to have_content("Changes:")
    expect(page).to have_content("Risk level: Medium-high risk")
    expect(page).to have_content("Assessed by: RiskAssessmentsRUs")
    expect(page).to have_content("Product assessed: Doll")
  end

  scenario "Editing a risk assessments associated products (without any other changes)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (1)"
    click_link "Serious risk: Teddy Bear"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    click_link "Edit risk assessment"

    expect_to_be_on_edit_risk_assessement_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    within_fieldset("Which products were assessed?") do
      uncheck "Teddy Bear"
    end

    within_fieldset("Which products were assessed?") do
      check "Doll"
    end

    click_button "Update risk assessment"

    click_link "Serious risk: Doll"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    expect(page).to have_summary_item(key: "Product assessed",    value: "Doll (#{doll.psd_ref})")
  end
end
