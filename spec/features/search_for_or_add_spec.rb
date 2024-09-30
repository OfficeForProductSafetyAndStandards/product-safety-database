require "rails_helper"

RSpec.feature "Search for or add a product", :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:product_one) { create(:product) }
  let(:product_two) { create(:product) }
  let(:retired_product) { create(:product) }

  before do
    sign_in(user)
    product_one
    product_two
    retired_product
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

  scenario "Creating a notification add existing product and a product that does not exist" do
    visit "/notifications/create"

    set_retired(retired_product)

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
    first('button.govuk-button[type="submit"][formnovalidate="formnovalidate"]').click

    expect(page).to have_content("There are no product records")

    visit "/notifications/your-notifications"

    expect(page).to have_content("Draft notifications")

    click_link "Make changes"

    expect(page).to have_content("Create a product safety notification")

    product = :first
    if product.present?
      expect(page).to have_content(product.name)
    end
  end

  scenario "Creating a notification add existing product with one retired product" do
    set_retired(retired_product)

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

    find_field("q-field").fill_in(with: retired_product.id)
    first('button.govuk-button[type="submit"][formnovalidate="formnovalidate"]').click

    expect(page).to have_content("There are no product records for \"#{retired_product.id}\"")

    visit "/notifications/your-notifications"

    have_content("Draft notifications")

    click_link "Make changes"

    expect(page).to have_content("Create a product safety notification")

    expect(page).not_to have_content(retired_product.name)
  end

private

  def set_retired(product)
    if product.present?
      product.retired_at = Time.zone.now
      product.save!
    end
  end
end
