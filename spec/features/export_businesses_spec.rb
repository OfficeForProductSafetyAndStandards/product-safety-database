require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Business export", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create :user, :all_data_exporter, :activated }
  let(:email) { delivered_emails.last }
  let(:export) { BusinessExport.find_by(user:) }
  let(:spreadsheet) do
    export.export_file.blob.open do |file|
      Roo::Excelx.new(file).sheet("Businesses")
    end
  end

  before do
    create(:business, trading_name: "ABC")
    create(:business, trading_name: "XYZ")
    Investigation.import scope: "not_deleted", force: true, refresh: :wait_for
    Business.import force: true, refresh: :wait_for

    sign_in(user)
  end

  scenario "with no filters selected" do
    visit businesses_path

    expect(page).to have_text "ABC"
    expect(page).to have_text "XYZ"

    click_link "XLSX (spreadsheet)"

    expect(page).to have_content "Your business export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "business_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq business_export_url(export)

    expect(spreadsheet.last_row).to eq(3)
    expect(spreadsheet.cell(2, 2)).to eq("ABC")
    expect(spreadsheet.cell(3, 2)).to eq("XYZ")
  end

  scenario "with search query" do
    visit businesses_path

    fill_in "Search", with: "XYZ"
    click_button "Submit search"

    expect(page).not_to have_text "ABC"
    expect(page).to have_text "XYZ"

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 2)).to eq("XYZ")
  end
end
