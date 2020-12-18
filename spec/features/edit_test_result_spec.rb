require "rails_helper"

RSpec.feature "Editing a test result", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product1) { create(:product_washing_machine, name: "MyBrand red washing machine") }
  let(:product2) { create(:product_washing_machine, name: "MyBrand blue washing machine") }
  let(:investigation) { create(:allegation, products: [product1, product2], creator: user) }
  let(:standards_product_was_tested_against) { [] }

  let(:test_result) do
    create(:test_result,
           investigation: investigation,
           product: product1,
           legislation: "General Product Safety Regulations 2005",
           date: Date.parse("2019-05-01"),
           result: :passed,
           details: "Provisional",
           standards_product_was_tested_against: standards_product_was_tested_against)
  end

  def go_edit_test_result
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/test-results/#{test_result.id}"

    click_link "Edit test result"

    expect_to_be_on_edit_test_result_page(case_id: investigation.pretty_id, test_result_id: test_result.id)

    # Check back link works
    click_link "Back"
    expect_to_be_on_test_result_page(case_id: investigation.pretty_id)
    click_link "Edit test result"
  end

  scenario "Editing a test result (with validation errors)" do
    travel_to Date.parse("4 May 2020") do
      go_edit_test_result
      # Check that form is pre-filled with existing values
      expect(page).to have_field("Against which legislation?", with: "General Product Safety Regulations 2005")
      within_fieldset "Date of test" do
        expect(page).to have_field("Day", with: "1")
        expect(page).to have_field("Month", with: "5")
        expect(page).to have_field("Year", with: "2019")
      end
      within_fieldset "What was the result?" do
        expect(page).to have_checked_field("Pass")
      end
      expect(page).to have_field("Further details", with: /\A\s*Provisional\z/)

      expect(page).to have_text("Currently selected file: test_result.txt")
      expect(page).to have_field("Attachment description", with: "\r\n" + test_result.document.metadata[:description])

      # Change some of the fields
      select "Consumer Protection Act 1987", from: "Against which legislation?"
      fill_in "Which standard was the product tested against?", with: "EN72,EN73"

      within_fieldset "Date of test" do
        fill_in "Day",   with: "2"
        fill_in "Month", with: "6"
      end

      within_fieldset "What was the result?" do
        choose "Fail"
      end

      fill_in "Further details", with: "Final result"

      find("details > summary", text: "Replace this file").click

      attach_file "Upload a file", Rails.root + "test/fixtures/files/test_result_2.txt"
      fill_in "Attachment description", with: "Final test result certificate"

      click_button "Update test result"

      expect_to_be_on_test_result_page(case_id: investigation.pretty_id)

      expect(page).to have_summary_item(key: "Date of test", value: "2 June 2019")
      expect(page).to have_summary_item(key: "Legislation", value: "Consumer Protection Act 1987")
      expect(page).to have_summary_item(key: "Standards", value: "EN72, EN73")
      expect(page).to have_summary_item(key: "Result", value: "Failed")
      expect(page).to have_summary_item(key: "Further details", value: "Final result")
      expect(page).to have_summary_item(key: "Attachment description", value: "Final test result certificate")

      expect(page).to have_link("test_result_2.txt")

      click_link "Back to #{investigation.decorate.pretty_description.downcase}"
      click_link "Activity"

      activity_card_body = page.find("p", text: "Edited by #{UserSource.new(user: investigation.creator_user).show(user)}").find(:xpath, "..")
      expect(activity_card_body).to have_text("Date of test: 2 June 2019")
      expect(activity_card_body).to have_text("Legislation: Consumer Protection Act 1987")
      expect(activity_card_body).to have_text("Standards: EN72, EN73")
      expect(activity_card_body).to have_text("Result: failed")
      expect(activity_card_body).to have_text("Further details: Final result")
      expect(activity_card_body).to have_text("Attached: test_result_2.txt")
      expect(activity_card_body).to have_text("Attachment description: Final test result certificate")
    end
  end

  context "with legacy test result" do
    let(:standards_product_was_tested_against) { nil }

    scenario "legacy test results with no standard tested against should enforce adding the standard" do
      go_edit_test_result

      click_button "Update test result"
      expect(page).to have_error_summary "Enter the standard the product was tested against"
    end
  end
end
