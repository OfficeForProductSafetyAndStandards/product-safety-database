require "rails_helper"

RSpec.feature "PRISM tasks", type: :feature do
  let(:user) { create(:user, :activated, roles: %w[prism]) }

  before do
    sign_in user
  end

  context "with normal risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, created_by_user_id: user.id) }

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

      click_button "Save and continue"

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

    context "when completing the final task of a section" do
      before do
        prism_risk_assessment.tasks_status["add_assessment_details"] = "completed"
        prism_risk_assessment.tasks_status["search_or_add_a_new_product"] = "completed"
        prism_risk_assessment.save!
      end

      scenario "task completion" do
        visit prism.risk_assessment_tasks_path(prism_risk_assessment)

        click_link "Add details about products in use and safety"

        fill_in "Name of the business that sold the product", with: "Test organisation"
        choose "No"
        check "BS EN 17022:2018"

        click_button "Save and complete tasks in this section"

        expect(page).to have_text("Determine and evaluate the level of product risk")
        expect(page).to have_text("You have completed 1 of 4 sections.")
      end
    end

    context "when completing a task that allows dynamic form fields" do
      before do
        prism_risk_assessment.tasks_status["add_assessment_details"] = "completed"
        prism_risk_assessment.tasks_status["search_or_add_a_new_product"] = "completed"
        prism_risk_assessment.tasks_status["add_details_about_products_in_use_and_safety"] = "completed"
        prism_risk_assessment.tasks_status["add_a_number_of_hazards_and_subjects_of_harm"] = "completed"
        prism_risk_assessment.state = "identify_completed"
        prism_risk_assessment.save!
      end

      scenario "task completion" do
        visit prism.risk_assessment_tasks_path(prism_risk_assessment)

        click_link "Choose hazard type"

        choose "Fire and explosion"
        fill_in "Hazard description", with: "Test description"

        click_button "Save and continue"

        click_button "Save and continue"

        expect(page).to have_text("Enter at least one step")

        fill_in "Step description", with: "Test description"
        choose "Decimal number"
        fill_in "Enter the probability as a decimal number.", with: "0.5"
        choose "Sole judgement or estimation"

        # TODO(ruben): enable JavaScript to allow testing the addition of multiple steps

        click_button "Save and continue"

        expect(page).to have_text("Determine severity of harm")
      end
    end

    scenario "accessing a step out-of-order" do
      visit prism.risk_assessment_define_path(prism_risk_assessment, id: "search_or_add_a_new_product")

      expect(page).to have_current_path(prism.risk_assessment_tasks_path(prism_risk_assessment))
    end
  end

  context "with serious risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment, :serious_risk, created_by_user_id: user.id) }

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
