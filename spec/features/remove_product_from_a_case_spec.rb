require "rails_helper"

RSpec.feature "Remove product from investigation", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)                  { create(:user, :opss_user, :activated) }
  let(:investigation)         { create(:enquiry, :with_products, creator: user) }
  let(:removal_reason)        { "I made a mistake" }
  let(:investigation_product) { investigation.investigation_products.first }
  let(:product)               { investigation_product.product }

  context "when investigation is closed" do
    before do
      ChangeCaseStatus.call!(investigation:, new_status: "closed", user:)
    end

    it "does not allow user to remove product" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      have_css("h2", text: product.name)

      expect(page).to have_no_link("Remove this #{product.name} product from the notification")
    end
  end

  context "when trying to remove a versioned product" do
    before do
      ChangeCaseStatus.call!(investigation:, new_status: "closed", user:)
      product.update!(subcategory: "changed")
      ChangeCaseStatus.call!(investigation:, new_status: "open", user:)
    end

    it "does not allow user to remove product" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      have_css("h2", text: product.name)

      expect(page).to have_no_link("Remove this #{product.name} product from the notification")
    end
  end

  context "when product does not have any linked supporting information" do
    it "allows user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      have_css("h2", text: product.name)

      click_link "Remove this #{product.name} product from the notification"

      expect(page).to have_content("The product record '#{product.name}' (#{product.psd_ref}) will be removed from the notification.")

      click_on "Save and continue"

      expect(page).to have_error_messages

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select yes if you want to remove the product from the notification"

      choose("Yes")
      click_on "Save and continue"

      expect(page).to have_error_messages
      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Enter the reason for removing the product"

      fill_in "Enter the reason for removing the product", with: removal_reason
      click_on "Save and continue"

      expect_confirmation_banner("The product record was removed from the notification")
      expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

      expect(page).not_to have_css("h2", text: product.name)
      expect(page).to have_css("p.govuk-body", text: "This notification has not added any products.")

      click_link "Activity"
      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

      expect(page.find("h3", text: "#{product.name} removed"))
        .to have_sibling(".govuk-body", text: removal_reason)
    end
  end

  context "when product has linked supporting information" do
    let!(:accident) { create :accident, investigation_product:, investigation: }
    let!(:risk_assessment) { create :risk_assessment, investigation_products: [investigation_product], investigation: }

    it "does not allow user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"
      click_link "Remove this #{product.name} product from the notification"

      expect(page).not_to have_css("h1", text: "Remove #{product.name}")

      expect(page).to have_css("h2", text: "Cannot remove the product from the notification")
      expect(page).to have_css("p", text: "This is because the product is associated with the following supporting information:")
      expect(page).to have_css("a", text: accident.decorate.supporting_information_title)
      expect(page).to have_css("a", text: risk_assessment.decorate.supporting_information_title)
    end
  end

  context "when there are two investigation products from the same base product model" do
    let(:investigation) { create(:enquiry, :with_products, creator: user) }
    let(:investigation_product) { investigation.investigation_products.first }
    let(:product) { investigation_product.product }

    it "allows the user to remove the product that was just added" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      close_and_reopen_case

      # Add the same product to the notification
      click_link "Add a product to the notification"
      expect(page).to have_text("Enter a PSD product record reference number")

      fill_in "reference", with: product.id
      click_button "Continue"

      expect(page).to have_text("Is this the correct product record to add to your notification?")
      expect(page).to have_text("#{product.brand} #{product.name}")

      choose "Yes"
      click_button "Save and continue"

      expect(page).to have_current_path("/cases/#{investigation.pretty_id}/products")
      expect(page).to have_text("The product record was added to the notification")

      # Now we see two products with the same PSD ref, one timestamped & the other not
      old_product_psd_text = "#{product.psd_ref}_#{investigation.reload.investigation_products.first.investigation_closed_at.to_i}"

      expect(page).to have_css(".govuk-summary-list__value", text: old_product_psd_text)
      expect(page).to have_css(".govuk-summary-list__value", text: "#{product.psd_ref} - The PSD reference number for this product record")

      # Only the timestamped product can be removed
      click_link "Remove this #{product.name} product from the notification"
      expect(page).to have_content("The product record '#{product.name}' (#{product.psd_ref}) will be removed from the notification.")

      click_on "Save and continue"

      expect(page).to have_error_messages

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select yes if you want to remove the product from the notification"

      choose("Yes")
      click_on "Save and continue"

      expect(page).to have_error_messages
      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Enter the reason for removing the product"

      fill_in "Enter the reason for removing the product", with: removal_reason
      click_on "Save and continue"

      expect_confirmation_banner("The product record was removed from the notification")
      expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

      expect(page).to have_css(".govuk-summary-list__value", text: old_product_psd_text)
      expect(page).not_to have_css(".govuk-summary-list__value", text: "#{product.psd_ref} - The PSD reference number for this product record")

      click_link "Activity"
      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

      expect(page.find("h3", text: "#{product.name} removed"))
        .to have_sibling(".govuk-body", text: removal_reason)
    end
  end

  def close_and_reopen_case
    ChangeCaseStatus.call!(investigation:, new_status: "closed", user:)
    product.update!(description: "wowthisisnew!")
    ChangeCaseStatus.call!(investigation:, new_status: "open", user:)
  end
end
