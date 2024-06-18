require "rails_helper"

RSpec.feature "Creating a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:investigation_with_same_user_title) do
    create(:allegation,
           creator: user,
           user_title: "title1")
  end
  let(:hazard_type) { "Burns" }
  let(:hazard_description) { "It's too hot" }
  let(:non_compliant_reason) { "does not comply with laws" }
  let(:reference_number) { "12345" }
  let(:case_name) { "Red hot case" }
  let!(:product) { create(:product) }

  describe "as a TS user" do
    let(:user) { create(:user, :activated) }

    scenario "Opening a new case (with validation error)" do
      sign_in(user)

      click_link "Notifications"
      click_link "Create a notification"
      click_link "Go to the products search page"

      click_link product.name
      click_link "Create a product notification"
      expect(page).to have_css("h1", text: "Why are you creating a notification?")
      click_button "Continue"

      expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

      within_fieldset("Why are you creating a notification?") do
        choose("A product is of concern")
      end

      click_button "Continue"

      expect(page).to have_css("h1", text: "Why is the product of concern?")

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select the options which are reasons for concern"

      within_fieldset("Why is the product of concern?") do
        check "The product is unsafe"
        check "The product is non-compliant"
      end

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select the primary hazard"
      expect(errors_list[1].text).to eq "Enter why the product is unsafe"
      expect(errors_list[2].text).to eq "Enter why the product is non-compliant"

      within_fieldset("Why is the product of concern?") do
        check "The product is unsafe"
        check "The product is non-compliant"
      end

      select hazard_type, from: "hazard_type"
      fill_in "Why is the product unsafe?", with: hazard_description
      fill_in "Why is the product non-compliant?", with: non_compliant_reason

      click_button "Continue"

      expect(page).to have_css("h1", text: "Do you want to add a reference number?")

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select yes to add a reference number to the notification"

      within_fieldset("Do you want to add a reference number?") do
        choose("Yes")
      end

      click_button "Continue"

      expect(errors_list[0].text).to eq "Enter a reference number"

      fill_in "Reference number", with: reference_number

      click_button "Continue"

      expect(page).to have_css("h1", text: "What is the notification name?")

      click_button "Save"

      expect(errors_list[0].text).to eq "Enter a notification name"

      find("#investigation-user-title-field-error").set(investigation_with_same_user_title.user_title)
      click_button "Save"

      expect(errors_list[0].text).to eq "The notification name has already been used in an open notification by your team"

      find("#investigation-user-title-field-error").set(case_name)

      click_button "Save"

      expect(page).to have_css("h1", text: "Notification created")
      expect(page).to have_content("Notification number#{Investigation.last.pretty_id}")

      click_link "View the notification"

      expect(page).to have_current_path("/cases/#{Investigation.last.pretty_id}")
      expect_summary_page_to_contain_correct_data

      click_link "Products (1)"
      expect(page.find("dt", text: "PSD ref")).to have_sibling("dd", text: product.psd_ref)
    end

    context "when a case is safe and compliant" do
      it "does not take user to the safety and compliance details page" do
        sign_in(user)

        click_link "Notifications"
        click_link "Create a notification"
        click_link "Go to the products search page"
        click_link product.name
        click_link "Create a product notification"

        expect(page).to have_css("h1", text: "Why are you creating a notification?")

        click_button "Continue"
        expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

        within_fieldset("Why are you creating a notification?") do
          choose("A product is safe and compliant")
        end

        click_button "Continue"

        expect(page).to have_css("h1", text: "Do you want to add a reference number?")
      end
    end

    context "when a user tries to navigate to a page outside of the wizard order" do
      it "does not take user to the safety and compliance details page" do
        sign_in(user)

        visit "/ts_investigation/case_name"

        expect(page).not_to have_css("h1", text: "What is the notification name?")
        expect(page).to have_no_current_path "ts_investigation/case_name"

        expect(page).to have_css("h1", text: "Why are you creating a notification?")
        expect(page).to have_no_current_path "ts_investigation/reason_for_creating"
      end
    end
  end

  describe "as an OPSS user" do
    let(:user) { create(:user, :activated, :opss_user) }

    scenario "Opening a new case (with validation error)" do
      sign_in(user)

      click_link "Notifications"
      click_link "Create a notification"
      click_link "Go to the products search page"

      click_link product.name
      click_link "Create a product notification"

      expect(page).to have_css("h1", text: "Why are you creating a notification?")
      click_button "Continue"

      expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

      within_fieldset("Why are you creating a notification?") do
        choose("A product is of concern")
      end

      click_button "Continue"

      expect(page).to have_css("h1", text: "Why is the product of concern?")

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select the options which are reasons for concern"

      within_fieldset("Why is the product of concern?") do
        check "The product is unsafe"
        check "The product is non-compliant"
      end

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select the primary hazard"
      expect(errors_list[1].text).to eq "Enter why the product is unsafe"
      expect(errors_list[2].text).to eq "Enter why the product is non-compliant"

      within_fieldset("Why is the product of concern?") do
        check "The product is unsafe"
        check "The product is non-compliant"
      end

      select hazard_type, from: "hazard_type"
      fill_in "Why is the product unsafe?", with: hazard_description
      fill_in "Why is the product non-compliant?", with: non_compliant_reason

      click_button "Continue"

      expect(page).to have_css("h1", text: "Do you want to add a reference number?")

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select yes to add a reference number to the notification"

      within_fieldset("Do you want to add a reference number?") do
        choose("Yes")
      end

      click_button "Continue"

      expect(errors_list[0].text).to eq "Enter a reference number"

      fill_in "Reference number", with: reference_number

      click_button "Continue"

      expect(page).to have_css("h1", text: "What is the notification name?")

      click_button "Save"

      expect(errors_list[0].text).to eq "Enter a notification name"

      find("#investigation-user-title-field-error").set(investigation_with_same_user_title.user_title)
      click_button "Save"

      expect(errors_list[0].text).to eq "The notification name has already been used in an open notification by your team"

      find("#investigation-user-title-field-error").set(case_name)

      click_button "Save"

      expect(page).to have_css("h1", text: "Notification created")
      expect(page).to have_content("Notification number#{Investigation.last.pretty_id}")

      click_link "View the notification"

      expect(page).to have_current_path("/cases/#{Investigation.last.pretty_id}")
      expect_summary_page_to_contain_correct_data

      click_link "Products (1)"
      expect(page.find("dt", text: "PSD ref")).to have_sibling("dd", text: product.psd_ref)
    end

    context "when a case is safe and compliant" do
      it "does not take user to the safety and compliance details page" do
        sign_in(user)

        click_link "Notifications"

        click_link "Create a notification"

        click_link "Go to the products search page"

        click_link product.name

        click_link "Create a product notification"

        expect(page).to have_css("h1", text: "Why are you creating a notification?")

        click_button "Continue"

        expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

        within_fieldset("Why are you creating a notification?") do
          choose("A product is safe and compliant")
        end

        click_button "Continue"

        expect(page).to have_css("h1", text: "Do you want to add a reference number?")
      end
    end

    context "when a user tries to navigate to a page outside of the wizard order" do
      it "does not take user to the safety and compliance details page" do
        sign_in(user)

        visit "/ts_investigation/case_name"

        expect(page).not_to have_css("h1", text: "What is the notification name?")
        expect(page).to have_no_current_path "ts_investigation/case_name"

        expect(page).to have_css("h1", text: "Why are you creating a notification?")
        expect(page).to have_no_current_path "ts_investigation/reason_for_creating"
      end
    end
  end

  def errors_list
    page.find(".govuk-error-summary__list").all("li")
  end

  def expect_summary_page_to_contain_correct_data
    expect(page.find("dt", text: "Notification name")).to have_sibling("dd", text: case_name)
    expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Product reported as unsafe and non-compliant")
    expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: hazard_type)
    expect(page.find("dt", text: "Hazard description")).to have_sibling("dd", text: hazard_description)
    expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: non_compliant_reason)
    expect(page.find("dt", text: "Reference")).to have_sibling("dd", text: reference_number)
  end
end
