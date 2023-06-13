require "rails_helper"

RSpec.feature "Adding new data to a case from the add new page", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_test_queue_adapter, type: :feature do
  let(:user)          { create(:user, :activated) }
  let(:investigation) { create(:enquiry, creator: user, products: [product1]) }
  let(:product1) { create(:product_washing_machine, name: "MyBrand Washing Machine") }

  before do
    sign_in_and_navigate_to_add_to_case_page
  end

  context "when user does not select anything to add to case" do
    it "shows error" do
      click_button "Continue"
      expect(page).to have_error_messages

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select the type of information you’re adding"
    end
  end

  context "when user selects `accident or incident`" do
    it "takes user to the new accident or incident page" do
      within_fieldset("What are you adding to the case?") do
        choose "Accident or incident"
      end

      click_button "Continue"
      expect_to_be_on_accident_or_incident_type_page
    end
  end

  context "when user selects `corrective action`" do
    it "takes user to the new corrective action page" do
      within_fieldset("What are you adding to the case?") do
        choose "Corrective action"
      end

      click_button "Continue"
      expect_to_be_on_record_corrective_action_for_case_page
    end
  end

  context "when user selects `correspondence`" do
    it "takes user to the new correspondence page" do
      within_fieldset("What are you adding to the case?") do
        choose "Correspondence"
      end

      click_button "Continue"
      expect_to_be_on_add_correspondence_page
    end
  end

  context "when user selects `test result`" do
    it "takes user to the new test result page" do
      within_fieldset("What are you adding to the case?") do
        choose "Test result"
      end

      click_button "Continue"
      expect_to_be_on_record_test_result_opss_funding_decision_page(case_id: investigation.pretty_id)
    end
  end

  context "when user selects `risk assessment`" do
    it "takes user to the new risk assessment page" do
      within_fieldset("What are you adding to the case?") do
        choose "Risk assessment"
      end

      click_button "Continue"
      expect_to_be_on_add_risk_assessment_for_a_case_page(case_id: investigation.pretty_id)
    end
  end

  context "when user selects `business`" do
    it "takes user to the new business page" do
      within_fieldset("What are you adding to the case?") do
        choose "Business"
      end

      click_button "Continue"
      expect_to_be_on_investigation_add_business_type_page
    end
  end

  def sign_in_and_navigate_to_add_to_case_page
    sign_in user
    visit "/cases/#{investigation.pretty_id}/add-to-case"

    expect_to_be_on_add_to_case_page
  end
end
