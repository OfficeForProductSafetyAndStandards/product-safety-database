require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Product export", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create :user, :psd_admin, :activated }
  let(:export) { ProductExport.find_by(user: user) }
  let(:email) { delivered_emails.last }

  before do
    create_list(:product, 18, created_at: 4.days.ago)
    Product.import force: true, refresh: :wait_for

    sign_in(user)
  end

  scenario "with no filters selected" do
    visit products_path

    click_link "Export as spreadsheet"
    expect(page).to have_content "Your product export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "product_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq product_export_url(export)
  end
end
