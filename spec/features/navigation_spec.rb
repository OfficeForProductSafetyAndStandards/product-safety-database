require "rails_helper"

RSpec.feature "App navigation", :with_stubbed_mailer, :with_stubbed_opensearch, :with_errors_rendered, type: :feature do
  let(:user) { create(:user, :activated, :opss_user) }

  let!(:product) { create(:product) }
  let!(:business) { create(:business) }
  let!(:investigation) { create(:project, :with_business, business_to_add: business) }

  before do
    sign_in(user)
    investigation.products << product
  end

  scenario "when accessing product page from list page navigation should let you go back to the list" do
    visit "/products/#{product.id}"
    expect(page).to have_link("Back", href: all_products_path)
  end

  scenario "when accessing business page from case page navigation should let you go back to the case" do
    visit "/cases/#{investigation.pretty_id}"

    within "main" do
      click_on "Businesses"
      click_on "business page"
    end

    expect(page).to have_content("Back to #{investigation.decorate.pretty_description}")
  end

  scenario "when accessing business page from list page navigation should let you go back to the list" do
    visit "/businesses/#{business.id}"
    expect(page).to have_css("li", text: "Businesses")
    expect(page).to have_css("li", text: business.trading_name)
  end
end
