require "rails_helper"
require 'sidekiq/testing'

RSpec.feature "Products listing", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, :with_test_queue_adapter, type: :feature do
  let(:user)             { create :user, :activated, has_viewed_introduction: true }
  let!(:iphone)          { create(:product_iphone,          created_at: 1.day.ago) }
  let!(:iphone_3g)       { create(:product_iphone_3g,       created_at: 2.days.ago) }
  let!(:washing_machine) { create(:product_washing_machine, created_at: 3.days.ago) }

  before do
    create_list(:product, 18, created_at: 4.days.ago)
    user.roles.create!(name: "psd_admin")
    sign_in(user)
    allow(ProductExportWorker).to receive(:perform_later) do
      ProductExportWorker.new.perform(Product.all, ProductExport.last.id, user)
    end
  end

  scenario "lists products according to search relevance" do
    Product.import refresh: :wait_for
    visit products_path

    click_link "Export as spreadsheet"
    expect(page).to have_content "Your product export is being prepared. You will receive an email when your export is ready to download."

    perform_enqueued_jobs

    expect(ProductExport.count).to eq 1
    expect(ProductExport.first.export_file.attached?).to eq true

    product_export_email = delivered_emails.last
    expect(product_export_email.action_name).to eq "product_export"
    expect(product_export_email.personalization[:name]).to eq user.name
    expect(product_export_email.personalization[:download_export_url]).to eq product_export_url(1)
  end
end
