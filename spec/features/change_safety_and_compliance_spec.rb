require "rails_helper"

RSpec.feature "Change safety and compliance details for a case", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user, reported_reason: "unsafe_and_non_compliant", hazard_type: "Burns", hazard_description: "FIRE FIRE FIRE", non_compliant_reason: "Covered in petrol") }

  context "when user is allowed to edit the case" do
    before do
      sign_in_and_visit_investigation_page
      visit_change_safety_and_compliance_page_and_expect_prefilled_values
    end
    
    context "when the case is unsafe and non compliant" do
      it "allows user to change details and make the case safe but uncompliant" do
        uncheck("It’s unsafe (or suspected to be)")
        fill_in("Why is the product non-compliant?", with: "No one really knows")

        click_button "Change"

        expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Non-compliant")
        expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text:  "No one really knows")

        expect(page).not_to have_css("dt", text: "Primary hazard")
        expect(page).not_to have_css("dt", text: "Description of hazard")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Allegation changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported reason: Non-compliant")
        expect(page).to have_content("Non-compliant reason: No one really knows")
      end

      it "allows user to change details and make the case unsafe but compliant" do
        uncheck("It’s non-compliant (or suspected to be)")
        select "Cuts", from: "What is the primary hazard?"
        fill_in("Why is the product unsafe?", with: "Far too sharp")

        click_button "Change"

        expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Unsafe")
        expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text:  "Cuts")
        expect(page.find("dt", text: "Description of hazard")).to have_sibling("dd", text: "Far too sharp")

        expect(page).not_to have_css("dt", text: "Compliance")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Allegation changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported reason: Unsafe")
        expect(page).to have_content("Hazard type: Cuts")
        expect(page).to have_content("Hazard description: Far too sharp")
      end

      it "allows user to change details and make the case safe and compliant" do
        uncheck("It’s non-compliant (or suspected to be)")
        uncheck("It’s unsafe (or suspected to be)")
        check("It’s safe and compliant")

        click_button "Change"

        expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Safe And Compliant")

        expect(page).not_to have_css("dt", text: "Primary hazard")
        expect(page).not_to have_css("dt", text: "Description of hazard")
        expect(page).not_to have_css("dt", text: "Compliance")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Allegation changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported reason: Safe And Compliant")
      end

      def sign_in_and_visit_investigation_page
        sign_in user
        visit "/cases/#{investigation.pretty_id}"
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Unsafe and non-compliant")
        expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: investigation.hazard_type)
        expect(page.find("dt", text: "Description of hazard")).to have_sibling("dd", text: investigation.hazard_description)
        expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: investigation.non_compliant_reason)
      end

      def visit_change_safety_and_compliance_page_and_expect_prefilled_values
        click_link "Change hazard_type"

        expect(page).to have_css("h1", text: "Why was the product reported?")
        expect(page).to have_checked_field("It’s unsafe (or suspected to be)")
        expect(page).to have_select("What is the primary hazard?", selected: investigation.hazard_type)
        expect(page).to have_field("Why is the product unsafe?", with: "\r\nFIRE FIRE FIRE")
        expect(page).to have_checked_field("It’s non-compliant (or suspected to be)")
        expect(page).to have_field("Why is the product non-compliant?", with: "\r\nCovered in petrol")
        expect(page).to have_unchecked_field("It’s safe and compliant")
      end
    end
  end
end
