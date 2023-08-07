require "rails_helper"

RSpec.feature "PRISM risk assessment dashboard", type: :feature do
  context "when the user has access to PRISM" do
    let(:user) { create(:user, :activated, roles: %w[prism]) }
    let(:draft_prism_risk_assessment) { create(:prism_risk_assessment, :with_harm_scenario, created_by_user_id: user.id) }
    let(:submitted_prism_risk_assessment) { create(:prism_risk_assessment, :submitted, :with_harm_scenario, created_by_user_id: user.id) }

    before do
      draft_prism_risk_assessment
      submitted_prism_risk_assessment

      sign_in user
    end

    scenario "visiting the PRISM risk assessment dashboard via the header link" do
      visit "/"

      expect(page).to have_link("Risk assessments", class: "psd-header__link")

      click_link "Risk assessments"

      expect(page).to have_text("Risk assessments")
      expect(page).to have_text(draft_prism_risk_assessment.harm_scenarios.first.description)
      expect(page).to have_link("Make changes")
      expect(page).to have_text(submitted_prism_risk_assessment.harm_scenarios.first.description)
      expect(page).to have_link("View assessment")
      expect(page).to have_link("Start a new risk assessment")
    end

    scenario "making changes to a PRISM risk assessment" do
      visit "/"

      click_link "Risk assessments"
      click_link "Make changes"

      expect(page).to have_text("Determine and evaluate the level of product risk")
    end
  end

  context "when the user does not have access to PRISM" do
    let(:user) { create(:user, :activated) }

    before do
      sign_in user
    end

    scenario "visiting the PRISM risk assessment dashboard via the header link" do
      visit "/"

      expect(page).not_to have_link("Risk assessments", class: "psd-header__link")
    end

    scenario "visiting the PRISM risk assessment dashboard directly" do
      expect { visit "/prism-risk-assessments/your-prism-risk-assessments" }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
