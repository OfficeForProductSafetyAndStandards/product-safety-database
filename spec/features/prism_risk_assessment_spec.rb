require "rails_helper"

RSpec.feature "PRISM risk assessment dashboard", type: :feature do
  context "when the user has access to PRISM" do
    let(:user) { create(:user, :activated, roles: %w[prism]) }
    let(:draft_prism_risk_assessment) { create(:prism_risk_assessment, :with_product, :with_harm_scenario, created_by_user_id: user.id) }
    let(:submitted_prism_risk_assessment) { create(:prism_risk_assessment, :submitted, :with_product, :with_harm_scenario, created_by_user_id: user.id) }

    before do
      sign_in user
    end

    context "with existing PRISM risk assessments" do
      before do
        draft_prism_risk_assessment
        submitted_prism_risk_assessment
      end

      scenario "visiting the PRISM risk assessment dashboard" do
        visit "/"

        expect(page).to have_link("Risk assessments", class: "psd-header__link")

        click_link "Risk assessments"

        expect(page).to have_text("Risk assessments")
        expect(page).to have_text(draft_prism_risk_assessment.product_name)
        expect(page).to have_text(draft_prism_risk_assessment.name)
        expect(page).to have_link("Make changes")
        expect(page).to have_link("Delete")
        expect(page).to have_text(submitted_prism_risk_assessment.product_name)
        expect(page).to have_text(submitted_prism_risk_assessment.name)
        expect(page).to have_link("View assessment")
        expect(page).to have_link("Start a new risk assessment")
      end

      scenario "starting a new PRISM risk assessment" do
        visit "/"

        click_link "Risk assessments"
        click_link "Start a new risk assessment"

        expect(page).to have_current_path("/products/all-products")
      end

      scenario "making changes to an existing PRISM risk assessment" do
        visit "/"

        click_link "Risk assessments"
        click_link "Make changes"

        expect(page).to have_current_path("/prism/risk-assessment/#{draft_prism_risk_assessment.id}/tasks")
      end

      scenario "deleting an existing PRISM risk assessment" do
        visit "/"

        click_link "Risk assessments"
        click_link "Delete"

        expect(page).to have_current_path("/prism/risk-assessment/#{draft_prism_risk_assessment.id}/tasks/remove?back_to=dashboard")
      end

      context "without an associated product" do
        before do
          draft_prism_risk_assessment.associated_products.destroy_all
        end

        scenario "making changes to an existing PRISM risk assessment" do
          visit "/"

          click_link "Risk assessments"

          expect(page).to have_text("Unknown product")

          click_link "Make changes"

          expect(page).to have_current_path("/products/all-products")
        end
      end
    end

    context "without existing PRISM risk assessments" do
      scenario "visiting the PRISM risk assessment dashboard" do
        visit "/"

        expect(page).to have_link("Risk assessments", class: "psd-header__link")

        click_link "Risk assessments"

        expect(page).to have_text("Risk assessments")
        expect(page).to have_text("You haven't added any risk assessments yet.")
        expect(page).to have_link("Start a new risk assessment")
      end
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
      visit "/prism-risk-assessments/your-prism-risk-assessments"
      expect(page).to have_http_status(:forbidden)
    end
  end
end
