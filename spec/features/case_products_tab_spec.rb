require "rails_helper"

RSpec.feature "Case product tab", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:original_investigation) { create(:allegation, creator: user) }
  let(:product) { original_investigation.products.first }

  before do
    sign_in user
  end

  context "when product has no other investigations linked to it" do
    it "does not show any additional cases on the cases tab" do
      visit "/cases/#{original_investigation.pretty_id}"

      click_link "Products (1)"

      click_link "Cases (0)"

      expect(page).to have_content "The original product record has not been included in any other cases."
    end
  end

  context "when product has other investigations linked to it" do
    let!(:investigation_1) { create(:allegation, creator: user, products: [product]) }
    let!(:investigation_2) { create(:allegation, creator: user, products: [product]) }
    let!(:investigation_3) { create(:allegation, creator: user, products: [product]) }

    it "shows additional cases on the cases tab" do
      visit "/cases/#{original_investigation.pretty_id}"

      click_link "Products (1)"

      click_link "Cases (3)"

      expect(page).to have_content "The original product record was or is also included in these 3 cases."

      expect(page).to have_css("dd.govuk-summary-list__value", text: investigation_1.pretty_id)
      expect(page).to have_css("dd.govuk-summary-list__value", text: investigation_2.pretty_id)
      expect(page).to have_css("dd.govuk-summary-list__value", text: investigation_3.pretty_id)
      expect(page).not_to have_css("dd.govuk-summary-list__value", text: original_investigation.pretty_id)
    end
  end
end
