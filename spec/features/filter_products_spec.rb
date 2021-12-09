require "rails_helper"

RSpec.feature "Case filtering", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :activated, organisation: organisation, has_viewed_introduction: true) }

  let!(:chemical_investigation)              { create(:allegation, hazard_type: "Chemical") }
  let!(:fire_investigation)                  { create(:allegation, hazard_type: "Fire") }
  let!(:drowning_investigation)              { create(:allegation, hazard_type: "Drowning") }

  let!(:fire_product_1)   { create(:product, name: "Hot product", investigations: [fire_investigation]) }
  let!(:fire_product_2)   { create(:product, name: "Very hot product", investigations: [fire_investigation]) }
  let!(:chemical_product) { create(:product, name: "Some lab stuff", investigations: [chemical_investigation]) }
  let!(:drowning_product) { create(:product, name: "Dangerous life vest", investigations: [drowning_investigation]) }

  before do
    Investigation.import refresh: :wait_for
    Product.import refresh: :wait_for
    sign_in(user)
    visit products_path
  end

  scenario "no filters applied shows all open cases" do
    expect(page).to have_content(fire_product_1.name)
    expect(page).to have_content(fire_product_2.name)
    expect(page).to have_content(chemical_product.name)
    expect(page).to have_content(drowning_product.name)
  end

  scenario "filtering by hazard type" do
    select "Fire", from: "Hazard type"
    click_button "Apply"

    expect(page).to have_content(fire_product_1.name)
    expect(page).to have_content(fire_product_2.name)
    expect(page).not_to have_content(chemical_product.name)
    expect(page).not_to have_content(drowning_product.name)
  end
end
