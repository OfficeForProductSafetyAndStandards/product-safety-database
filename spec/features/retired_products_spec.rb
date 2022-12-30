require "rails_helper"

RSpec.feature "Retired products", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:opss_user) { create(:user, :activated, :opss_user) }
  let(:non_opss_user) { create(:user, :activated) }
  let(:live_product) { create(:product) }
  let(:retired_product) { create(:product, :retired) }

  context "when signed in as an opss user" do
    before do
      sign_in opss_user
    end

    scenario "the user can view a live product" do
      visit product_path(live_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{live_product.id} - The PSD reference for this product record")
    end

    scenario "the user can view a retired product" do
      visit product_path(retired_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{retired_product.id} - The PSD reference for this product record")
    end
  end

  context "when signed in as a non-opss user" do
    before do
      sign_in non_opss_user
    end

    scenario "the user can view a live product" do
      visit product_path(live_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{live_product.id} - The PSD reference for this product record")
    end

    scenario "the user can not view a retired product" do
      expect { visit product_path(retired_product) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when a product is linked to a closed historic case" do
    let!(:investigation) { travel(-3.years) { create(:allegation, products: [live_product], creator: opss_user) } }

    before do
      travel(-2.years) do
        live_product.update! name: "Name at closure"
        ChangeCaseStatus.call! investigation:, new_status: "closed", user: opss_user
      end

      travel(-19.months) do
        live_product.update! name: "Name after closure"
      end

      sign_in opss_user
    end

    scenario "a live product shows its timestamped PSD reference" do
      visit "/cases/#{investigation.pretty_id}/products"
      expect(page).to have_css("h3", text: "Name at closure")
      expect(page).to have_css("dl.govuk-summary-list dd.govuk-summary-list__value", text: "#{live_product.psd_ref}_#{investigation.date_closed.to_i}")
    end

    scenario "a retired product shows its timestamped PSD reference" do
      live_product.mark_as_retired!

      visit "/cases/#{investigation.pretty_id}/products"
      expect(page).to have_css("h3", text: "Name at closure")
      expect(page).to have_css("dl.govuk-summary-list dd.govuk-summary-list__value", text: "#{live_product.psd_ref}_#{investigation.date_closed.to_i}")
    end
  end
end