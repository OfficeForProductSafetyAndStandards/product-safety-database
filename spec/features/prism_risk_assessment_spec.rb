require "rails_helper"

RSpec.feature "PRISM risk assessment dashboard", type: :feature do
  context "when the user has access to PRISM" do
    let(:user) { create(:user, :activated, roles: %w[prism]) }

    before do
      sign_in user
    end

    scenario "visiting the PRISM risk assessment dashboard via the header link" do
      visit "/"

      expect(page).to have_link("Risk assessments", class: "psd-header__link")

      click_link "Risk assessments"

      expect(page).to have_text("Risk assessments")
      expect(page).to have_link("Start a new risk assessment")
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
