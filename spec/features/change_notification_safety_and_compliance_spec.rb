require "rails_helper"

RSpec.feature "Change safety and compliance details for a case", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user) { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:notification) { create(:notification, creator: user, reported_reason: "unsafe_and_non_compliant", hazard_type: "Burns", hazard_description: "FIRE FIRE FIRE", non_compliant_reason: "Covered in petrol") }

  context "when user is allowed to edit the case" do
    before do
      sign_in_and_visit_investigation_page
      visit_change_reported_reason_page_and_expect_prefilled_values_for_unsafe_and_non_compliant
    end

    context "when the case is unsafe and non compliant" do
      it "allows user to change details and make the case safe but uncompliant" do
        choose("As non-compliant")

        click_button "Continue"

        expect_prefilled_values_for_non_compliant_product

        fill_in("Why is the product non-compliant?", with: "No one really knows")

        click_button "Save"

        expect(page).to have_current_path("/cases/#{notification.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as non-compliant")
        expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text:  "No one really knows")

        expect(page).not_to have_css("dt", text: "Primary hazard")
        expect(page).not_to have_css("dt", text: "Hazard description")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Safety and compliance status changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported as: Non-compliant")
        expect(page).to have_content("Compliance: No one really knows")
      end

      it "allows user to change details and make the case unsafe but compliant" do
        choose("As unsafe")

        click_button "Continue"

        expect_prefilled_values_for_unsafe_product

        select "Cuts", from: "What is the primary hazard?"
        fill_in("Why is the product unsafe?", with: "Far too sharp")

        click_button "Save"

        expect(page).to have_current_path("/cases/#{notification.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as unsafe")
        expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: "Cuts")
        expect(page.find("dt", text: "Hazard description")).to have_sibling("dd", text: "Far too sharp")

        expect(page).not_to have_css("dt", text: "Compliance")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Safety and compliance status changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported as: Unsafe")
        expect(page).to have_content("Primary hazard: Cuts")
        expect(page).to have_content("Hazard description: Far too sharp")
      end

      it "allows user to change details and make the case safe and compliant" do
        choose("As safe and compliant")

        click_button "Continue"

        expect(page).to have_current_path("/cases/#{notification.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as safe and compliant")

        expect(page).not_to have_css("dt", text: "Primary hazard")
        expect(page).not_to have_css("dt", text: "Hazard description")
        expect(page).not_to have_css("dt", text: "Compliance")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Safety and compliance status changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported as: Safe and compliant")
      end
    end

    context "when a user cancels before completing all the steps" do
      it "does not save the changes" do
        choose("As non-compliant")

        click_button "Continue"

        expect_prefilled_values_for_non_compliant_product

        click_link "Cancel"

        expect(page).to have_current_path("/cases/#{notification.pretty_id}")
        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as unsafe and non-compliant")
      end
    end
  end

  context "when the case safety and compliance data is not set" do
    context "when user does not fill in the appropriate fields" do
      let(:notification) { create(:notification, creator: user) }

      it "raises error and does not allow user to change safety and compliance details until they are correctly filled in" do
        sign_in user
        visit "/cases/#{notification.pretty_id}"
        visit_change_reported_reason_page_with_no_values_selected

        click_button "Continue"

        errors_list = page.find(".govuk-error-summary__list").all("li")
        expect(errors_list[0].text).to eq "Reported reason cannot be blank"

        choose("As unsafe and non-compliant")

        click_button "Continue"

        click_button "Save"

        errors_list = page.find(".govuk-error-summary__list").all("li")

        expect(errors_list[0].text).to eq "Select the primary hazard"
        expect(errors_list[1].text).to eq "Enter why the product is unsafe"
        expect(errors_list[2].text).to eq "Enter why the product is non-compliant"

        fill_in("Why is the product non-compliant?", with: "No one really knows")
        select "Cuts", from: "What is the primary hazard?"
        fill_in("Why is the product unsafe?", with: "Far too sharp")

        click_button "Save"

        expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as unsafe and non-compliant")
        expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: "Cuts")
        expect(page.find("dt", text: "Hazard description")).to have_sibling("dd", text: "Far too sharp")

        click_link "Activity"
        expect(page).to have_css("h3", text: "Safety and compliance status changed")
        expect(page).to have_content("Changes:")
        expect(page).to have_content("Reported as: Unsafe")
        expect(page).to have_content("Primary hazard: Cuts")
        expect(page).to have_content("Hazard description: Far too sharp")
        expect(page).to have_content("Compliance: No one really knows")
      end
    end
  end

  def sign_in_and_visit_investigation_page
    sign_in user
    visit "/cases/#{notification.pretty_id}"
    expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as unsafe and non-compliant")
    expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: notification.hazard_type)
    expect(page.find("dt", text: "Hazard description")).to have_sibling("dd", text: notification.hazard_description)
    expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: notification.non_compliant_reason)
  end

  def visit_change_reported_reason_page_and_expect_prefilled_values_for_unsafe_and_non_compliant
    click_link "Edit the safety and compliance"

    expect(page).to have_css("legend", text: "How is the product being reported?")
    expect(page).to have_unchecked_field("As unsafe")
    expect(page).to have_unchecked_field("As non-compliant")
    expect(page).to have_checked_field("As unsafe and non-compliant")
    expect(page).to have_unchecked_field("As safe and compliant")
    expect_to_have_notification_breadcrumbs
  end

  def visit_change_reported_reason_page_with_no_values_selected
    click_link "Edit the safety and compliance"

    expect(page).to have_css("legend", text: "How is the product being reported?")
    expect(page).to have_unchecked_field("As unsafe")
    expect(page).to have_unchecked_field("As non-compliant")
    expect(page).to have_unchecked_field("As unsafe and non-compliant")
    expect(page).to have_unchecked_field("As safe and compliant")
    expect_to_have_notification_breadcrumbs
  end

  def expect_prefilled_values_for_non_compliant_product
    expect(page).to have_css("legend", text: "Why is the product of concern?")
    expect(page).not_to have_field("Why is the product unsafe?", with: "FIRE FIRE FIRE")
    expect(page).not_to have_select("What is the primary hazard?", selected: notification.hazard_type)
    expect(page).to have_field("Why is the product non-compliant?", with: "Covered in petrol")
    expect_to_have_notification_breadcrumbs
  end

  def expect_prefilled_values_for_unsafe_product
    expect(page).to have_css("legend", text: "Why is the product of concern?")
    expect(page).to have_field("Why is the product unsafe?", with: "FIRE FIRE FIRE")
    expect(page).to have_select("What is the primary hazard?", selected: notification.hazard_type)
    expect(page).not_to have_field("Why is the product non-compliant?", with: "Covered in petrol")
    expect_to_have_notification_breadcrumbs
  end
end
