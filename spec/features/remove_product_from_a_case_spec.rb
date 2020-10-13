require "rails_helper"

RSpec.feature "Removing a product from a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  let(:product) do
    create(:product,
           name: "MyBrand dishwasher",
           description: "Integrated white dishwasher",
           category: "Electrical appliances and equipment")
  end

  let(:investigation) { create(:allegation, creator: user, products: [product]) }

  scenario "Removing a product from a case" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/products"

    expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

    click_link "Remove product"

    expect_to_be_on_remove_product_from_case_page(case_id: investigation.pretty_id, product_id: product.id)

    expect(page).to have_text("MyBrand dishwasher")
    expect(page).to have_text("Integrated white dishwasher")
    expect(page).to have_text("Electrical appliances and equipment")

    click_button "Remove product"

    expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)

    expect(page).not_to have_text("MyBrand dishwasher")
    expect(page).to have_text("No products")
  end
end
