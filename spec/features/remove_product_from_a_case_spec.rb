require "rails_helper"

RSpec.feature "Remove product from investigation", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)           { create(:user, :opss_user, :activated) }
  let(:investigation)  { create(:enquiry, :with_products, creator: user) }
  let(:removal_reason) { "I made a mistake" }
  let(:product)        { investigation.products.first }

  context "when product does not have any linked supporting information" do
    it "allows user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"

      have_css("h2", text: product.name)

      click_link "Remove product"

      expect(page).to have_css("h1", text: "Remove #{product.name}")

      click_on "Submit"

      expect(page).to have_error_messages

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select yes if you want to remove the product from the case"

      choose("Yes")
      click_on "Submit"

      expect(page).to have_error_messages
      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Enter the reason for removing the product from the case"

      fill_in "Reason for removing the product from the case", with: removal_reason
      click_on "Submit"

      expect_confirmation_banner("Product was successfully removed.")
      expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

      expect(page).not_to have_css("h2", text: product.name)
      expect(page).to have_css("p.govuk-body", text: "This case has not added any products.")

      click_link "Activity"
      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

      expect(page.find("h3", text: "#{product.name} removed"))
        .to have_sibling(".govuk-body", text: removal_reason)
    end
  end

  context "when product has linked supporting information" do
    let!(:accident) { create :accident, product:, investigation: }
    let!(:risk_assessment) { create :risk_assessment, products: [product], investigation: }
    let!(:corrective_action) { create :corrective_action, product: }

    it "does not allow user to remove product from investigation" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/products"
      click_link "Remove product"

      expect(page).not_to have_css("h1", text: "Remove #{product.name}")

      expect(page).to have_css("h2", text: "Cannot remove the product from the case")
      expect(page).to have_css("p", text: "This is because the product is associated with the following supporting information:")
      expect(page).to have_css("a", text: accident.decorate.supporting_information_title)
      expect(page).to have_css("a", text: risk_assessment.decorate.supporting_information_title)

      # NOTE: corrective_action belongs to another investigation
      expect(page).not_to have_css("a", text: corrective_action.decorate.supporting_information_title)
    end
  end
end
