require "rails_helper"

RSpec.feature "Product taxonomy", :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, :with_test_queue_adapter, type: :feature do
  let!(:user) { create(:user, roles: %w[support_portal update_product_taxonomy]) }
  let!(:product_category_one) { create(:product_category) }
  let!(:product_category_two) { create(:product_category) }
  let!(:product_subcategory_one) { create(:product_subcategory, product_category: product_category_one) }
  let!(:product_subcategory_two) { create(:product_subcategory, product_category: product_category_one) }
  let!(:product_subcategory_three) { create(:product_subcategory, product_category: product_category_two) }
  let(:taxonomy_file) { Rails.root.join "test/fixtures/files/taxonomy.xlsx" }
  let(:text_file) { Rails.root.join "test/fixtures/files/attachment_filename.txt" }
  let(:empty_file) { Rails.root.join "test/fixtures/files/empty_file.xlsx" }

  before do
    configure_requests_for_support_domain
    sign_in user
  end

  after do
    reset_domain_request_mocking
    Capybara.reset_sessions!
  end

  scenario "Viewing the current product taxonomy" do
    expect(page).to have_h1("Dashboard")

    click_link "Product taxonomy"
    click_link "View current product taxonomy"

    expect(page).to have_h1("Current product taxonomy")

    expect(page).to have_text(product_category_one.name)
    expect(page).to have_text(product_category_two.name)
    expect(page).to have_text(product_subcategory_one.name)
    expect(page).to have_text(product_subcategory_two.name)
    expect(page).to have_text(product_subcategory_three.name)
  end

  scenario "Updating the product taxonomy" do
    expect(page).to have_h1("Dashboard")

    click_link "Product taxonomy"
    click_link "Upload new product taxonomy file"

    expect(page).to have_h1("Upload new product taxonomy file")

    click_on "Upload product taxonomy file"

    expect(page).to have_link("Select a file", href: "#product-taxonomy-import-import-file-field-error")

    attach_file "product_taxonomy_import[import_file]", text_file
    click_on "Upload product taxonomy file"

    expect(page).to have_link("The selected file must be an Excel file (XLSX)", href: "#product-taxonomy-import-import-file-field-error")

    attach_file "product_taxonomy_import[import_file]", empty_file
    click_on "Upload product taxonomy file"

    expect(page).to have_link("The selected file must be larger than 0MB", href: "#product-taxonomy-import-import-file-field-error")

    perform_enqueued_jobs do
      attach_file "product_taxonomy_import[import_file]", taxonomy_file
      click_on "Upload product taxonomy file"

      expect(page).to have_css("div.govuk-notification-banner", text: "Product taxonomy file uploaded - refresh to check progress")
    end

    expect(page).to have_text("File uploaded")
    expect(page).to have_text("taxonomy.xlsx")
  end
end
