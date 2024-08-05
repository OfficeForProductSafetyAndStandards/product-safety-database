require "rails_helper"

RSpec.feature "Add notification with search", :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:existing_product) { create(:product) }
  let(:new_product_attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end
  let(:image_file) { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:text_file) { Rails.root.join "test/fixtures/files/attachment_filename.txt" }

  before do
    sign_in(user)

    existing_product
  end

  scenario "Creating a notification with the normal flow search for and add a product" do
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")

    click_link "Search for or add a product"

    expect(page).to have_content("PSD reference:")

    click_button "Select", match: :first

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"
  end

  scenario "Creating a notification with the normal flow search for and add multiple products" do
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_selector(:id, "task-list-0-0-status", text: "Not yet started")

    click_link "Search for or add a product"
    click_button "Select", match: :first

    within_fieldset "Do you need to add another product?" do
      choose "Yes"
    end

    click_button "Continue"

    expect(page).to have_content("Choose the product for your notification")

    expect(page).to have_content("Search by product name, description or PSD reference")

    expect(page).to have_content("Product details")

    find_field("q-field").fill_in(with: "ABC123")

    find('button.govuk-button[type="submit"][formnovalidate="formnovalidate"]').click

    expect(page).to have_content("There are no product records")

    # TODO: figure out how to go back to the previous screen "Search for or add a product"
  end
end
