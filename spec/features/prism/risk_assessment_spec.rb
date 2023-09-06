require "rails_helper"

RSpec.feature "PRISM risk assessment", type: :feature do
  let(:user) { create(:user, :activated, roles: %w[prism]) }

  before do
    sign_in user
  end

  context "with normal risk" do
    let(:prism_risk_assessment) { create(:prism_risk_assessment) }

    scenario "risk assessment completion" do
      visit prism.risk_assessment_tasks_path(prism_risk_assessment)

      click_link "Add assessment details"

      fill_in "Name of assessor", with: "Test name"
      fill_in "Name of assessment organisation", with: "Test organisation"

      click_button "Save and continue"

      expect(page).to have_text("This is a placeholder page.")

      click_button "Save and continue"

      fill_in "Name of the business that sold the product", with: "Test company"
      choose "Yes" # Can the total number of products in use be estimated?
      fill_in "Estimated number of products in use", with: 1_000_000
      check "BS EN 17072:2018" # Product safety legislation and standards

      click_button "Save and complete tasks in this section"

      expect(page).to have_text("You have completed 1 of 4 sections.")

      click_link "Add a number of hazards"

      choose "3" # Number of hazards identified

      click_button "Save and complete tasks in this section"

      expect(page).to have_text("You have completed 2 of 4 sections.")

      click_link "task-list-2-0-0-status" # Choose hazard type (scenario 1)

      choose "Electrical" # What is the hazard type?
      fill_in "Hazard description", with: "This is a test description 1"

      click_button "Save and continue"

      choose "Particular group of users" # Who is the product aimed at?
      fill_in "Description of user type including age group if applicable. For example, children 2-3 years.", with: "Children"
      check "Unintended users" # Who else might be at risk?

      click_button "Save and continue"

      expect(page).to have_text("For\nElectrical\nPlaceholder product\nThis is a test description 1\nAffected users: Particular group of users")

      fill_in "Step description", with: "Test description for step 1"

      click_button "Save and continue"

      choose "Level 3"
      choose "Yes" # Does the hazard have the potential to harm more than one person in a single incident?

      click_button "Save and continue"

      expect(page).to have_text("For\nElectrical\nPlaceholder product\nThis is a test description 1\nAffected users: Particular group of users\nSeverity of harm: Level 3\nMultiple casualties: yes")

      choose "Decimal number" # In what format would you like to express the probability of harm?
      fill_in "Enter the probability as a decimal number.", with: "0.25"
      choose "Sole judgement or estimation" # How did you decide on the probability of harm?

      click_button "Save and continue"

      expect(page).to have_text("Hazard details\nHazard typeElectrical")
      expect(page).to have_text("Hazard descriptionThis is a test description 1")
      expect(page).to have_text("Harm scenario\nAffected usersParticular group of users")
      expect(page).to have_text("Step 1Test description for step 1Probability of harm: 0.25Evidence: Sole judgement or estimation")
      expect(page).to have_text("Overall probability of harm1 in 4")
      expect(page).to have_text("Severity levelLevel 3, multiple casualties: yes")
      expect(page).to have_text("Scenario risk level\nSerious risk")

      click_button "Confirm and create scenario"

      click_link "Add another scenario"

      click_link "task-list-2-0-1-status" # Choose hazard type (scenario 2)

      choose "Mechanical" # What is the hazard type?
      fill_in "Hazard description", with: "This is a test description 2"

      click_button "Save and continue"

      choose "General population" # Who is the product aimed at?

      click_button "Save and continue"

      expect(page).to have_text("For\nMechanical\nPlaceholder product\nThis is a test description 2\nAffected users: General population")

      fill_in "Step description", with: "Test description for step 1"

      click_button "Save and continue"

      choose "Level 1"
      choose "No" # Does the hazard have the potential to harm more than one person in a single incident?

      click_button "Save and continue"

      choose "Frequency number" # In what format would you like to express the probability of harm?
      fill_in "Enter the probability as a frequency number.", with: "100"
      choose "Sole judgement or estimation" # How did you decide on the probability of harm?

      click_button "Save and continue"

      expect(page).to have_text("Hazard details\nHazard typeMechanical")
      expect(page).to have_text("Hazard descriptionThis is a test description 2")
      expect(page).to have_text("Harm scenario\nAffected usersGeneral population")
      expect(page).to have_text("Step 1Test description for step 1Probability of harm: 1 in 100Evidence: Sole judgement or estimation")
      expect(page).to have_text("Overall probability of harm1 in 100")
      expect(page).to have_text("Severity levelLevel 1, multiple casualties: no")
      expect(page).to have_text("Scenario risk level\nMedium risk")

      click_button "Confirm and create scenario"

      expect(page).to have_text("You have completed 3 of 4 sections.")

      click_link "Review the overall product risk level"

      expect(page).to have_text("Electrical1 in 4Level 3Serious risk")
      expect(page).to have_text("Mechanical1 in 100Level 1Medium risk")
      expect(page).to have_css("p[data-test='overall-product-risk-level']", text: "Serious risk")
      expect(page).to have_button("Add a risk level plus label")

      click_button "Save and continue"

      choose "Medium" # What is the level of uncertainty associated with the risk assessment?
      choose "No" # Has sensitivity analysis been undertaken?

      click_button "Save and continue"

      expect(page).to have_text("Is the number of products estimated to be in use expected to change?\nAs recorded in the assessment\nEstimated 1,000,000 products in use")
      choose "No changes" # Is the number of products estimated to be in use expected to change?

      expect(page).to have_text("Does the uncertainty level have implications for risk management decisions?\nAs recorded in the assessment\nMedium level of uncertainty")
      choose "evaluation-uncertainty-level-implications-for-risk-management-field" # Does the uncertainty level have implications for risk management decisions? (No)

      choose "Similar" # How does the risk level compare to that of comparable products?

      expect(page).to have_text("Is there potential for multiple casualties in a single incident?\nAs recorded in the assessment\nYes")
      choose "evaluation-multiple-casualties-true-field" # Is there potential for multiple casualties in a single incident? (Yes)

      choose "evaluation-significant-risk-differential-no-field" # Is there a significant risk differential? (No)

      expect(page).to have_text("Are there people at increased risk?\nAs recorded in the assessment\nChildren")
      choose "evaluation-people-at-increased-risk-true-field" # Are there people at increased risk? (Yes)

      choose "evaluation-relevant-action-by-others-unknown-field" # Is relevant action planned or underway by another MSA or other organisation? (Unknown)

      choose "evaluation-factors-to-take-into-account-field" # As regards the nature of the risk, are there factors to take account of in relation to risk management decisions? (No)

      click_button "Save and continue"

      choose "evaluation-other-hazards-field" # As well as the hazard associated with the non-compliance, does the product have any other hazards that can and do cause harm? (No)

      choose "evaluation-low-likelihood-high-severity-no-field" # Is this a low likelihood but high severity risk? (No)

      expect(page).to have_text("Is there a risk to non-users?\nAs recorded in the assessment\nNon-users might be at risk")
      choose "evaluation-risk-to-non-users-field" # Is there a risk to non-users? (No)

      choose "evaluation-aimed-at-vulnerable-users-yes-field" # Is this a type of product aimed at vulnerable users? (Yes)

      choose "evaluation-designed-to-provide-protective-function-no-field" # Is the product designed to provide a protective function? (No)

      choose "evaluation-user-control-over-risk-field" # Can users exert any control over the risk? (No)

      click_button "Save and continue"

      choose "Risk is intolerable"

      expect { click_button "Save and continue" }.to raise_error(ActionView::MissingTemplate)

      # TODO(ruben): Add more tests once workflow is complete
    end
  end
  # TODO(ruben): Add tests for serious risk products when the workflow is ready
end
