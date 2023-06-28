require "rails_helper"

RSpec.feature "PRISM tasks", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context "with normal risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment) }

    scenario "visiting the tasks page" do
      visit prism.tasks_path(prism_risk_assessment)

      expect(page).to have_text("Determine and evaluate the level of product risk")
      expect(page).to have_text("You have completed 0 of 4 sections.")
    end
  end

  context "with serious risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, :serious_risk) }

    scenario "visiting the tasks page" do
      visit prism.tasks_path(prism_risk_assessment)

      expect(page).to have_text("Evaluate the product deemed serious risk")
      expect(page).to have_text("You have completed 0 of 2 sections.")
    end
  end
end
