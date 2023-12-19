require "rails_helper"

# This spec tests generic features of the task list.
# See `risk_assessment_spec.rb` for a full set of tests
# for the entire workflow.
RSpec.feature "PRISM tasks", type: :feature do
  let(:user) { create(:user, :activated, roles: %w[prism]) }

  before do
    sign_in user
  end

  context "with normal risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, :with_product, created_by_user_id: user.id) }

    scenario "tasks page", :aggregate_failures do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_text("Determine and evaluate the level of product risk")
      expect(page).to have_text("You have completed 0 of 5 sections.")
    end

    scenario "task list", :aggregate_failures do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add assessment details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Not yet started")

      expect(page).not_to have_link("Add details about products in use and safety")
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

      click_button "Save and continue"

      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add assessment details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Completed")

      expect(page).to have_link("Add details about products in use and safety")
      expect(page).to have_selector("#task-list-0-1-status", text: "Not yet started")

      click_link "Add assessment details"
      click_button "Save as draft"

      expect(page).to have_text("Determine and evaluate the level of product risk")
    end

    context "when completing the final task of a section" do
      before do
        prism_risk_assessment.tasks_status["add_assessment_details"] = "completed"
        prism_risk_assessment.save!
      end

      scenario "task completion", :aggregate_failures do
        visit prism.risk_assessment_tasks_path(prism_risk_assessment)

        click_link "Add details about products in use and safety"

        fill_in "Name of the business that sold the product", with: "Test organisation"
        choose "No" # Can the total number of products in use be estimated?
        select "ATEX 2016"
        select "Fireworks Act 2003 / Fireworks Regulations 2004"

        click_button "Save and complete tasks in this section"

        expect(page).to have_text("Determine and evaluate the level of product risk")
        expect(page).to have_text("You have completed 1 of 5 sections.")
      end
    end

    context "when completing a task that allows dynamic form fields" do
      before do
        prism_risk_assessment.tasks_status["add_assessment_details"] = "completed"
        prism_risk_assessment.tasks_status["add_details_about_products_in_use_and_safety"] = "completed"
        prism_risk_assessment.tasks_status["add_a_number_of_hazards"] = "completed"
        prism_risk_assessment.state = "identify_completed"
        prism_risk_assessment.save!
      end

      scenario "task completion" do
        visit prism.risk_assessment_tasks_path(prism_risk_assessment)

        click_link "Choose hazard type"

        choose "Fire and explosion" # What is the hazard type?
        fill_in "Hazard description", with: "Test description"

        click_button "Save and continue"

        choose "General population" # Who is the product aimed at?

        click_button "Save and continue"

        click_button "Save and continue"

        expect(page).to have_text("Enter at least one step")

        fill_in "Step description", with: "Test description"

        # Enable JavaScript in tests to allow testing the addition of multiple steps

        click_button "Save and continue"

        expect(page).to have_text("Determine severity of harm")
      end
    end

    scenario "accessing a step out-of-order" do
      visit prism.risk_assessment_define_path(prism_risk_assessment, id: "add_details_about_products_in_use_and_safety")

      expect(page).to have_current_path(prism.risk_assessment_tasks_path(prism_risk_assessment))
    end
  end

  context "with serious risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, :serious_risk, :with_product, created_by_user_id: user.id) }

    scenario "tasks page", :aggregate_failures do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_text("Evaluate the product deemed serious risk")
      expect(page).to have_text("You have completed 0 of 3 sections.")
    end

    scenario "task list", :aggregate_failures do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_link("Add evaluation details")
      expect(page).to have_selector("#task-list-0-0-status", text: "Not yet started")

      expect(page).not_to have_link("Complete product risk evaluation")
      expect(page).to have_selector("#task-list-1-0-status", text: "Cannot start yet")
    end
  end

  context "when signed in as a user without the PRISM role" do
    let(:non_prism_user) { create(:user, :activated) }
    let(:prism_risk_assessment) { create(:prism_risk_assessment, created_by_user_id: non_prism_user.id) }

    before do
      sign_out
      sign_in non_prism_user
    end

    scenario "visiting the task list" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_current_path("/403")
    end
  end

  context "when not signed in" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment) }

    before do
      sign_out
    end

    scenario "visiting the task list" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      expect(page).to have_current_path("/sign-in")
    end
  end
end
