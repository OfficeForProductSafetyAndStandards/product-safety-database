require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Product export", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create :user, :all_data_exporter, :activated }
  let(:email) { delivered_emails.last }
  let(:export) { ProductExport.find_by(user:) }
  let(:spreadsheet) do
    export.export_file.blob.open do |file|
      Roo::Excelx.new(file).sheet("product_info")
    end
  end

  let!(:product_1) { create(:product, name: "ABC") }
  let!(:product_2) { create(:product, name: "XYZ") }
  let!(:hazardous_product) { create(:product, name: "STU") }
  let!(:investigation) { create(:allegation, :reported_unsafe, :with_products, products: [hazardous_product]) }
  let(:hazard_type) { investigation.hazard_type }

  before do
    Product.import force: true, refresh: :wait_for
    Investigation.import force: true, refresh: :wait_for

    sign_in(user)
  end

  scenario "with no filters selected" do
    visit products_path

    expect(page).to have_text product_1.name
    expect(page).to have_text product_2.name
    expect(page).to have_text hazardous_product.name

    click_link "XLSX (spreadsheet)"

    expect(page).to have_content "Your product export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "product_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq product_export_url(export)

    expect(spreadsheet.last_row).to eq(4)
    expect(spreadsheet.cell(2, 13)).to eq(product_1.name)
    expect(spreadsheet.cell(3,13)).to eq(product_2.name)
    expect(spreadsheet.cell(4, 13)).to eq(hazardous_product.name)
  end

  scenario "with search query" do
    visit products_path

    fill_in "Search", with: product_2.name
    click_button "Submit search"

    expect(page).not_to have_text product_1.name
    expect(page).not_to have_text hazardous_product.name
    expect(page).to have_text product_2.name

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 13)).to eq(product_2.name)
  end

  scenario "with hazard type filter" do
    visit products_path

    select hazard_type, from: "Hazard type"
    click_button "Submit search"

    expect(page).not_to have_text product_1.name
    expect(page).not_to have_text product_2.name
    expect(page).to have_text hazardous_product.name

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 13)).to eq(hazardous_product.name)
  end
end
