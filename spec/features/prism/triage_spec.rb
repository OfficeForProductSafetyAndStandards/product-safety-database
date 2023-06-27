require "rails_helper"

RSpec.feature "PRISM triage", type: :feature do
  scenario "visiting the start page" do
    visit prism.root_path

    expect(page).to have_text("Determine and evaluate the level of risk presented by a consumer product")
    expect(page).to have_link("Start now")

    expect(page).not_to have_link("Sign out")
  end

  scenario "selecting the product requires a full risk assessment" do
    visit prism.root_path

    click_link "Start now"

    expect(page).to have_text("Does the product require a full risk assessment?")

    click_button "Continue"

    expect(page).to have_text("Select whether the product requires a full risk assessment")

    choose "Yes"
    click_button "Continue"

    expect(page).to have_text("Sign in")
  end

  scenario "selecting the product may not require a full risk assessment" do
    visit prism.root_path

    click_link "Start now"
    choose "Not clear"
    click_button "Continue"

    expect(page).to have_text("Perform risk triage")
  end

  context "when signed in" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    scenario "selecting that a product poses a serious risk" do
      visit prism.serious_risk_path

      expect(page).to have_text("Is the product likely to pose a serious risk that would justify exemption from a full risk assessment?")

      click_button "Continue"

      expect(page).to have_text("Select whether the product poses a serious risk")

      choose "Yes"
      click_button "Continue"

      expect(page).to have_text("Are there any factors to indicate the product risk to be less than serious?")
    end

    scenario "selecting that a product does not post a serious risk" do
      visit prism.serious_risk_path

      expect(page).to have_text("Is the product likely to pose a serious risk that would justify exemption from a full risk assessment?")

      choose "No"

      # TODO(ruben): Change once the task page is ready
      expect { click_button "Continue" }.to raise_exception(ActionController::MissingExactTemplate)
    end

    scenario "selecting that a product does have rebuttable factors to posing a serious risk" do
      visit prism.serious_risk_rebuttable_path

      expect(page).to have_text("Are there any factors to indicate the product risk to be less than serious?")

      click_button "Continue"

      expect(page).to have_text("Select whether there are any factors")

      choose "Yes"
      click_button "Continue"

      expect(page).to have_text("Enter a description")

      fill_in "form_serious_risk_rebuttable[description]", with: "Lorem ipsum"

      # TODO(ruben): Change once the task page is ready
      expect { click_button "Continue" }.to raise_exception(ActionController::MissingExactTemplate)
    end

    scenario "selecting that a product does not have rebuttable factors to posing a serious risk" do
      visit prism.serious_risk_rebuttable_path

      expect(page).to have_text("Are there any factors to indicate the product risk to be less than serious?")

      choose "No"

      # TODO(ruben): Change once the task page is ready
      expect { click_button "Continue" }.to raise_exception(ActionController::MissingExactTemplate)
    end
  end
end
