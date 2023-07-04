require "rails_helper"

RSpec.feature "PRISM tasks", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context "with normal risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment) }

    scenario "tasks page" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_text("Determine and evaluate the level of product risk")
      expect(page).to have_text("You have completed 0 of 4 sections.")
    end

    scenario "task list" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add assessment details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Not started")

      expect(page).not_to have_link("Search or add a new product")
      expect(page).to have_selector("#task-list-0-1-status", text: "Cannot start yet")
    end

    scenario "task completion" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      click_link "Add assessment details"

      click_button "Save and continue"

      expect(page).to have_text("Enter the full name of the assessor")
      expect(page).to have_text("Enter the name of the assessment organisation")

      fill_in "Name of assessor", with: "Test name"
      fill_in "Name of assessment organisation", with: "Test organisation"

      # TODO(ruben): change once the next task is ready
      expect { click_button "Save and continue" }.to raise_error(ActionView::MissingTemplate)

      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add assessment details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Completed")

      expect(page).to have_link("Search or add a new product")
      expect(page).to have_selector("#task-list-0-1-status", text: "Not started")

      expect(page).not_to have_link("Add details about products in use and safety")
      expect(page).to have_selector("#task-list-0-2-status", text: "Cannot start yet")

      click_link "Add assessment details"
      click_button "Save as draft"

      expect(page).to have_text("Determine and evaluate the level of product risk")
    end
  end

  context "with serious risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, :serious_risk) }

    scenario "tasks page" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_text("Evaluate the product deemed serious risk")
      expect(page).to have_text("You have completed 0 of 2 sections.")
    end

    scenario "task list" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add evaluation details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Not started")

      expect(page).not_to have_link("Search or add a new product")
      expect(page).to have_selector("#task-list-0-1-status", text: "Cannot start yet")
    end
  end
end
