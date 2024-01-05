require "rails_helper"

RSpec.feature "Notification task list", :with_stubbed_antivirus, :with_stubbed_mailer, :with_opensearch, :with_product_form_helper do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:existing_product) { create(:product) }
  let(:new_product_attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end

  before do
    sign_in(user)

    existing_product
  end

  scenario "Creating an empty notification" do
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")
  end

  scenario "Creating a notification from an existing product" do
    visit "/notifications/create/from-product/#{existing_product.id}"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
  end

  scenario "Adding a new product to an existing notification" do
    visit "/notifications/create"

    click_link "Search for or add a product"
    click_link "Add a product"

    select new_product_attributes[:category], from: "Product category"

    fill_in "Product subcategory", with: new_product_attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: new_product_attributes[:brand]
    fill_in "Product name", with: new_product_attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: new_product_attributes[:barcode]
    fill_in "Other product identifiers", with: new_product_attributes[:product_code]
    fill_in "Webpage", with: new_product_attributes[:webpage]

    within_fieldset("Was the product placed on the market before 1 January 2021?") do
      choose when_placed_on_market_answer(new_product_attributes[:when_placed_on_market])
    end

    within_fieldset("Is the product counterfeit?") do
      choose counterfeit_answer(new_product_attributes[:authenticity])
    end

    within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
      page.find("input[value='#{new_product_attributes[:has_markings]}']").choose
    end

    within_fieldset("Select product marking") do
      new_product_attributes[:markings].each { |marking| check(marking) } if new_product_attributes[:has_markings] == "markings_yes"
    end

    select new_product_attributes[:country_of_origin], from: "Country of origin"

    fill_in "Description of product", with: new_product_attributes[:description]

    click_button "Save"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
  end

  scenario "Adding an existing product" do
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")

    click_link "Search for or add a product"
    click_button "Select", match: :first

    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Completed")
  end
end
