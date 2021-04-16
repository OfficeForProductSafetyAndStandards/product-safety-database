require "rails_helper"

RSpec.feature "Remove product from investigation", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)           { create(:user, :activated) }
  let(:investigation)  { create(:enquiry, :with_products, creator: user) }
  let(:removal_reason) { "I made a mistake" }
  let(:product)        { investigation.products.first }

  context "when product does not have any linked supporting information" do
    it "allows user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      have_css("h2", text: product.name)

      click_link "Remove product"

      expect(page).to have_content "Remove #{product.name}"

      click_on "Submit"

      expect(page).to have_error_messages

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select yes if you want to remove the product from the case"

      choose("Yes")
      click_on "Submit"

      expect(page).to have_error_messages
      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Reason cannot be blank"

      fill_in "Reason for removing the product from the case", with: removal_reason
      click_on "Submit"

      expect_confirmation_banner("Product was successfully removed.")
      expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

      expect(page).not_to have_text(product.name)
      expect(page).to have_text("No products")

      click_link "Activity"
      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect(page).to have_content("#{product.name} removed")
      expect(page).to have_content(removal_reason)
    end
  end

  context "when product has linked supporting information" do
    before do
      create(:accident, product: product)
      create(:risk_assessment, products: [product])
      create(:corrective_action, product: product)
    end

    it "does not allow user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"
      click_link "Remove product"

      expect(page).not_to have_content "Remove #{product.name}"
      expect(page).to have_content "Cannot remove the product from the case because it's associated with following supporting information"
    end
  end
end
