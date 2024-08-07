require "rails_helper"

RSpec.feature "Adding a risk assessment to a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:risk_assessment_file) { Rails.root.join "test/fixtures/files/new_risk_assessment.txt" }
  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, team:, name: "Jo Bloggs") }

  let(:product_one) { create(:product_washing_machine, name: "MyBrand washing machine model X") }
  let(:product_two) { create(:product_washing_machine, name: "MyBrand washing machine model Y") }

  let(:business_one) { create(:business, trading_name: "MyBrand Inc") }
  let(:business_two) { create(:business, trading_name: "MyBrand Distributors") }

  let(:investigation) do
    create(:allegation, products: [product_one, product_two],
                        risk_level: nil,
                        investigation_businesses:
             [
               build(:investigation_business, business: business_one),
               build(:investigation_business, business: business_two)
             ],
                        creator: user)
  end

  let(:investigation_with_no_businesses) { create(:allegation, products: [product_one, product_two], creator: user) }

  let(:investigation_with_single_product) { create(:allegation, products: [product_one], creator: user) }

  let(:investigation_with_serious_risk_level) { create(:allegation, products: [product_one], creator: user, risk_level: :serious) }

  let(:investigation_with_not_conclusive_risk_level) { create(:allegation, products: [product_one], creator: user, risk_level: :not_conclusive) }

  let(:investigation_with_no_products) { create(:allegation, products: [], creator: user) }

  before do
    create(:team, name: "OtherCouncil Trading Standards")
  end

  scenario "Adding a risk assessment to a case with a multiple products (with validation errors)" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}"
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    click_link "Add a risk assessment"

    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs

    expect(page).to have_select("Choose team",
                                options: ["", "OtherCouncil Trading Standards"],
                                selected: [])

    expect(page).to have_select("Choose business",
                                options: ["", "MyBrand Distributors", "MyBrand Inc"],
                                selected: [])

    click_button "Attach risk assessment"

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter the date of the assessment"
    expect(errors_list[1].text).to eq "Select the risk level"
    expect(errors_list[2].text).to eq "Select who completed the assessment"
    expect(errors_list[3].text).to eq "You must choose at least one product"
    expect(errors_list[4].text).to eq "You must upload the risk assessment"

    attach_file "Upload the risk assessment", risk_assessment_file

    click_button "Attach risk assessment"

    expect(page).to have_css("#current-attachment-details a", text: risk_assessment_file.basename.to_s)
    expect(page).not_to have_text("You must upload the risk assessment")

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "MyCouncil Trading Standards"
    end

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    fill_in("Further details (optional)", with: "Products risk-assessed in response to incident.")

    click_button "Attach risk assessment"

    # Skip the 'Case risk level' page as it is automatically updated to match

    click_link "Serious risk: MyBrand washing machine model X"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Date of assessment",  value: "3 April 2020")
    expect(page).to have_summary_item(key: "Risk level",          value: "Serious risk")
    expect(page).to have_summary_item(key: "Assessed by",         value: "MyCouncil Trading Standards")
    expect(page).to have_summary_item(key: "Product assessed",    value: "MyBrand washing machine model X (#{product_one.psd_ref})")
    expect(page).to have_summary_item(key: "Further details", value: "Products risk-assessed in response to incident.")

    expect(page).to have_text("new_risk_assessment.txt")

    click_link investigation.pretty_id
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Notification risk level set to serious risk")
    expect(page).to have_text("Risk level changed by Jo Bloggs")

    expect(page).to have_text("Risk assessment")
    expect(page).to have_text("Added by Jo Bloggs")
    expect(page).to have_text("Date of assessment: 3 April 2020")
    expect(page).to have_text("Risk level: Serious risk")
    expect(page).to have_text("Assessed by: MyCouncil Trading Standards")
    expect(page).to have_text("Product assessed: MyBrand washing machine model X")
    expect(page).to have_text("Attached: new_risk_assessment.txt")
    expect(page).to have_text("Further details: Products risk-assessed in response to incident.")

    expect(page).to have_link("View risk assessment")
  end

  scenario "Adding a risk assessment done by a business associated with the case" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/risk-assessments/new"
    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "A business related to the notification"
    end

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    click_button "Attach risk assessment"

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    expect(page).to have_text("Select business related to the notification")
    select "MyBrand Inc", from: "Choose business"

    attach_file "Upload the risk assessment", risk_assessment_file

    click_button "Attach risk assessment"

    # Skip the 'Case risk level' page as it is automatically updated to match

    click_link "Serious risk: MyBrand washing machine model X"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Assessed by", value: "MyBrand Inc")

    click_link investigation.pretty_id
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Assessed by: MyBrand Inc")
  end

  scenario "Adding a risk assessment done by someone else" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/risk-assessments/new"
    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation.pretty_id)

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("Who completed the assessment?") do
      choose "Someone else"
    end

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    click_button "Attach risk assessment"

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    click_button "Attach risk assessment"

    expect(page).to have_text("Enter organisation name")
    fill_in "Organisation name", with: "RiskAssessmentsRUs"

    click_button "Attach risk assessment"

    # Check that field retains value when there's a validation error
    expect(page).to have_field("Organisation name", with: "RiskAssessmentsRUs")

    within_fieldset("Which products were assessed?") do
      check "MyBrand washing machine model X"
    end

    attach_file "Upload the risk assessment", risk_assessment_file
    click_button "Attach risk assessment"

    # Skip the 'Case risk level' page as it is automatically updated to match

    click_link "Serious risk: MyBrand washing machine model X"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Assessed by", value: "RiskAssessmentsRUs")

    click_link investigation.pretty_id
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Assessed by: RiskAssessmentsRUs")
  end

  scenario "Adding a risk assessment to a case with no associated businesses" do
    sign_in(user)

    visit "/cases/#{investigation_with_no_businesses.pretty_id}/risk-assessments/new"
    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation_with_no_businesses.pretty_id)

    expect(page).not_to have_field("A business related to the notification")
    expect(page).not_to have_select("Choose business")
  end

  scenario "Adding a risk assessment to a case with a single product associated" do
    sign_in(user)

    visit "/cases/#{investigation_with_single_product.pretty_id}/risk-assessments/new"
    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation_with_single_product.pretty_id)

    expect(page).not_to have_css("fieldset", text: "Which products were assessed?")

    expect(page).to have_text("Product assessed")
    expect(page).to have_text("MyBrand washing machine model X")

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "High risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "MyCouncil Trading Standards"
    end

    attach_file "Upload the risk assessment", risk_assessment_file

    click_button "Attach risk assessment"

    # Skip the 'Case risk level' page as it is automatically updated to match

    click_link "High risk: MyBrand washing machine model X"

    expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation_with_single_product.pretty_id)

    expect(page).to have_summary_item(key: "Product assessed", value: "MyBrand washing machine model X (#{product_one.psd_ref})")
  end

  scenario "Adding a risk assessment to a case where the assessed risk level matches the existing case risk level" do
    sign_in(user)

    visit "/cases/#{investigation_with_serious_risk_level.pretty_id}/risk-assessments/new"

    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation_with_serious_risk_level.pretty_id)

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "MyCouncil Trading Standards"
    end

    attach_file "Upload the risk assessment", risk_assessment_file

    click_button "Attach risk assessment"

    # Skip the 'Case risk level' page as it already matches

    expect_to_be_on_supporting_information_page(case_id: investigation_with_serious_risk_level.pretty_id)
  end

  scenario "Adding a risk assessment to a case where the assessed risk level does not match the existing case risk level" do
    sign_in(user)

    visit "/cases/#{investigation_with_not_conclusive_risk_level.pretty_id}/risk-assessments/new"

    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation_with_not_conclusive_risk_level.pretty_id)

    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose "Serious risk"
    end

    within_fieldset("Who completed the assessment?") do
      choose "MyCouncil Trading Standards"
    end

    attach_file "Upload the risk assessment", risk_assessment_file

    click_button "Attach risk assessment"

    expect_to_be_on_update_case_risk_level_from_risk_assessment_page(case_id: investigation_with_not_conclusive_risk_level.pretty_id)

    within_fieldset("Do you want to match this notification risk level to the risk assessment level?") do
      choose("No, keep the current notification risk level unchanged")
    end

    click_button "Save"

    expect_to_be_on_supporting_information_page(case_id: investigation_with_not_conclusive_risk_level.pretty_id)
  end

  scenario "Attempting to add a risk assessment to a case with no associated products" do
    sign_in(user)

    visit "/cases/#{investigation_with_no_products.pretty_id}/risk-assessments/new"
    expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation_with_no_products.pretty_id)

    expect(page).to have_text("You need to add a product to the notification before you can add a risk assessment.")
  end
end
