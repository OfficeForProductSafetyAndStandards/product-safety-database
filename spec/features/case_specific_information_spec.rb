require "rails_helper"

RSpec.describe "Case specific information spec", :with_stubbed_mailer do
  let(:team) { create :team }
  let(:other_team) { create :team }
  let(:user) { create :user, :opss_user, :activated, has_viewed_introduction: true, team: }
  let(:team_mate) { create :user, :activated, has_viewed_introduction: true, team: }
  let(:other_user) { create :user, :activated, has_viewed_introduction: true, team: other_team }
  let(:notification) { create :notification, creator: user }
  let(:product_one) { create :product }
  let(:product_two) { create :product }
  let(:product_three) { create :product }
  let(:product_four) { create :product }
  let(:new_batch_numbers) { "abc, def, 999" }
  let(:new_customs_code) { "eng98989" }

  context "when investigation has multiple linked products" do
    before do
      InvestigationProduct.create!(investigation_id: notification.id, product_id: product_one.id, customs_code: "ABC123", batch_number: "1", affected_units_status: "unknown")
      InvestigationProduct.create!(investigation_id: notification.id, product_id: product_two.id, customs_code: "XYZ987", batch_number: "2", affected_units_status: "exact", number_of_affected_units: "91")
      InvestigationProduct.create!(investigation_id: notification.id, product_id: product_three.id, customs_code: "ZZZ999", batch_number: "3", affected_units_status: "approx", number_of_affected_units: "10000")
      InvestigationProduct.create!(investigation_id: notification.id, product_id: product_four.id, customs_code: "BBB222", batch_number: "1000", affected_units_status: "not_relevant")
    end

    it "shows all info on notification specific info section of notification page" do
      sign_in user
      visit investigation_path(notification)
      expect_investigation_products_to_be_listed_with_oldest_first

      within("dl#product-0") do
        expect(page).to have_css("dt.govuk-summary-list__key", text: "Batch numbers")
        expect(page).to have_css("dd.govuk-summary-list__value", text: InvestigationProduct.first.batch_number)

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Customs codes")
        expect(page).to have_css("dd.govuk-summary-list__value", text: InvestigationProduct.first.customs_code)

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Units affected")
        expect(page).to have_css("dd.govuk-summary-list__value", text: "Unknown")
      end

      within("dl#product-1") do
        expect(page).to have_css("dt.govuk-summary-list__key", text: "Units affected")
        expect(page).to have_css("dd.govuk-summary-list__value", text: "91 Exact number")
      end

      within("dl#product-2") do
        expect(page).to have_css("dt.govuk-summary-list__key", text: "Units affected")
        expect(page).to have_css("dd.govuk-summary-list__value", text: "10000 Approximate number")
      end

      within("dl#product-3") do
        expect(page).to have_css("dt.govuk-summary-list__key", text: "Units affected")
        expect(page).to have_css("dd.govuk-summary-list__value", text: "Not relevant")
      end
    end

    context "when user has permission to update the investigation" do
      before do
        sign_in team_mate
        visit investigation_path(notification)
      end

      it "allows editing of batch numbers" do
        within("dl#product-0") do
          click_link "Edit the batch numbers for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_batch_numbers_page(notification_product_id: InvestigationProduct.first.id)

        expect(page).to have_field("batch_number", with: InvestigationProduct.first.batch_number)

        fill_in "batch_number", with: new_batch_numbers

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The notification information was updated")

        within("dl#product-0") do
          expect(page).to have_css("dt.govuk-summary-list__key", text: "Batch numbers")
          expect(page).to have_css("dd.govuk-summary-list__value", text: new_batch_numbers)
        end

        click_link "Activity"
        expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
        expect(page).to have_css("h3", text: "Notification specific product information updated")
        expect(page).to have_content("Batch number: #{new_batch_numbers}")

        expect(delivered_emails.last.personalization[:subject_text]).to eq "Notification batch number updated"
      end

      it "allows editing of customs code" do
        within("dl#product-0") do
          click_link "Edit the customs codes for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_customs_code_page(notification_product_id: InvestigationProduct.first.id)

        expect(page).to have_field("customs_code", with: InvestigationProduct.first.customs_code)

        fill_in "customs_code", with: new_customs_code

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The notification information was updated")

        within("dl#product-0") do
          expect(page).to have_css("dt.govuk-summary-list__key", text: "Customs code")
          expect(page).to have_css("dd.govuk-summary-list__value", text: new_customs_code)
        end

        click_link "Activity"
        expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
        expect(page).to have_css("h3", text: "Notification specific product information updated")
        expect(page).to have_content("Customs code: #{new_customs_code}")

        expect(delivered_emails.last.personalization[:subject_text]).to eq "Notification customs code updated"
      end

      it "allows editing of units affected" do
        within("dl#product-0") do
          click_link "Edit the units affected for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_units_affected_page(notification_product_id: InvestigationProduct.first.id)

        expect(page).to have_checked_field("Unknown")

        choose "Exact number"

        fill_in "number-of-affected-units-form-exact-units-field", with: ""

        click_button "Save"

        errors_list = page.find(".govuk-error-summary__list").all("li")
        expect(errors_list[0].text).to eq "Enter how many units are affected"

        choose "Exact number"

        fill_in "number-of-affected-units-form-exact-units-field-error", with: "100"

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The notification information was updated")

        within("dl#product-0") do
          expect(page).to have_css("dt.govuk-summary-list__key", text: "Units affected")
          expect(page).to have_css("dd.govuk-summary-list__value", text: "100 Exact number")
        end

        click_link "Activity"
        expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
        expect(page).to have_css("h3", text: "Notification specific product information updated")
        expect(page).to have_content("Affected units status: exact")
        expect(page).to have_content("Number of affected units: 100")

        expect(delivered_emails.last.personalization[:subject_text]).to eq "Notification units affected updated"
      end

      it "allows adding of UCR numbers" do
        within("dl#product-0") do
          click_link "Edit the UCR numbers for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_ucr_numbers_page(notification_product_id: InvestigationProduct.first.id)

        fill_in "investigation_product_ucr_numbers_attributes_0_number", with: "ucr-123"

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The UCR numbers were updated")

        within("dl#product-0") do
          expect(page).to have_css("dt.govuk-summary-list__key", text: "UCR numbers")
          expect(page).to have_css("dd.govuk-summary-list__value", text: "ucr-123")
        end

        click_link "Activity"
        expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
        expect(page).to have_css("h3", text: "Notification specific product information updated")
        expect(page).to have_content("UCR numbers: ucr-123")

        expect(delivered_emails.last.personalization[:subject_text]).to eq "Notification UCR numbers updated"
      end

      it "allows edit of UCR numbers" do
        within("dl#product-0") do
          click_link "Edit the UCR numbers for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_ucr_numbers_page(notification_product_id: InvestigationProduct.first.id)

        fill_in "investigation_product_ucr_numbers_attributes_0_number", with: "ucr-123"

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The UCR numbers were updated")

        within("dl#product-0") do
          click_link "Edit the UCR numbers for #{InvestigationProduct.first.product.name}"
        end
        expect_to_be_on_edit_ucr_numbers_page(notification_product_id: InvestigationProduct.first.id)

        fill_in "investigation_product_ucr_numbers_attributes_0_number", with: "ucr-456"

        click_button "Save"
        expect_to_be_on_case_page(case_id: notification.pretty_id)

        expect(page).to have_content("The UCR numbers were updated")

        within("dl#product-0") do
          expect(page).to have_css("dt.govuk-summary-list__key", text: "UCR numbers")
          expect(page).to have_css("dd.govuk-summary-list__value", text: "ucr-456")
        end

        click_link "Activity"
        expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
        expect(page).to have_css("h3", text: "Notification specific product information updated")
        expect(page).to have_content("UCR numbers: ucr-456")

        expect(delivered_emails.last.personalization[:subject_text]).to eq "Notification UCR numbers updated"
      end
    end

    context "when user does not have permissions to update the investigation" do
      before do
        sign_in other_user
        visit investigation_path(notification)
      end

      it "does not allow editing of the notification specific information" do
        expect(page).not_to have_link("Edit the batch numbers for #{product_one.name}")
        expect(page).not_to have_link("Edit the customs codes for #{product_one.name}")
      end
    end
  end

  context "when investigation has no linked products" do
    it "shows empty notification specific info section of notification page" do
      sign_in user
      visit investigation_path(notification)
      expect(page).to have_css("h4", text: "You can add this information after a product has been added to the notification.")
    end
  end
end

def product_titles
  all("h4.opss-secondary-text").map(&:text)
end

def expect_investigation_products_to_be_listed_with_oldest_first
  expect(product_titles).to eq(["#{product_one.name} (#{product_one.psd_ref})", "#{product_two.name} (#{product_two.psd_ref})", "#{product_three.name} (#{product_three.psd_ref})", "#{product_four.name} (#{product_four.psd_ref})"])
end
