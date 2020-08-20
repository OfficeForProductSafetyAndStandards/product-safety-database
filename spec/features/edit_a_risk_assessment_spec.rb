require "rails_helper"

RSpec.feature "Editing a risk assessment on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/new_risk_assessment.txt") }

  let(:user) { create(:user, :activated) }
  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }

  let(:investigation) { create(:allegation, creator: user, products: [teddy_bear, doll]) }

  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:risk_assessment) do
    create(:risk_assessment,
           investigation: investigation,
           assessed_on: Date.parse("2020-01-02"),
           assessed_by_team: team,
           risk_level: :serious,
           products: [teddy_bear],
           risk_assessment_file: risk_assessment_file)
  end

  scenario "Editing a risk assessment (with validation errors)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "View risk assessment"

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

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)

    expect(page).to have_summary_item(key: "Risk level",          value: "Medium-high risk")
    expect(page).to have_summary_item(key: "Assessed by",         value: "RiskAssessmentsRUs")
    expect(page).to have_summary_item(key: "Product assessed",    value: "Doll")
  end
end
