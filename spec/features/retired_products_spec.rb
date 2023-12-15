require "rails_helper"

RSpec.feature "Retired products", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:opss_user) { create(:user, :activated, :opss_user) }
  let(:non_opss_user) { create(:user, :activated) }
  let(:owning_team) { create(:team) }
  let(:live_product) { create(:product, owning_team:) }
  let(:retired_product) { create(:product, :retired, owning_team:) }

  context "when signed in as an opss user" do
    before do
      sign_in opss_user
    end

    scenario "the user can view a live product" do
      visit product_path(live_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{live_product.id} - The PSD reference number for this product record")
      expect(page.find("dt", text: "Product record owner")).to have_sibling("dd", text: owning_team.name)
      expect(page).not_to have_content("This product record has been retired and can no longer be added to cases")
      expect(page).to have_content "This product record is currently owned by #{owning_team.name}."
      expect(page).to have_link "Create a product case"
    end

    scenario "the user can view a live product's owner" do
      visit owner_product_path(live_product)
      expect(page).to have_summary_item(key: "Record owner", value: owning_team.name)
    end

    scenario "the user can view a retired product" do
      visit product_path(retired_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{retired_product.id} - The PSD reference number for this product record")
      expect(page).not_to have_css("dt", text: "Product record owner")
      expect(page).to have_content("This product record has been retired and can no longer be added to cases")
      expect(page).not_to have_content "This product record is currently owned by #{Team.find(live_product.owning_team_id).name}."
      expect(page).not_to have_link "Create a product case"
    end

    scenario "the user can view a retired product's owner" do
      visit owner_product_path(retired_product)
      expect(page).to have_summary_item(key: "Record owner", value: owning_team.name)
    end
  end

  context "when signed in as a non-opss user" do
    before do
      sign_in non_opss_user
    end

    scenario "the user can view a live product" do
      visit product_path(live_product)
      expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{live_product.id} - The PSD reference number for this product record")
    end

    scenario "the user can view a live product's owner" do
      visit owner_product_path(live_product)
      expect(page).to have_summary_item(key: "Record owner", value: owning_team.name)
    end

    context "when user tries to view a retired product" do
      before do
        create(:allegation, products: [retired_product])
        retired_product.reload.decorate
      end

      it "shows retired product page and links to the investigations related to the product" do
        visit product_path(retired_product)
        expect(page).to have_css("h1", text: "The product record does not exist")
        expect(page).to have_link(retired_product.investigations.first.title, href: "/cases/#{retired_product.investigations.first.pretty_id}")
      end
    end

    scenario "the user can not view a retired product's owner" do
      visit owner_product_path(retired_product)
      expect(page).to have_http_status(:not_found)
      expect(page).to have_text("Page not found")
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
