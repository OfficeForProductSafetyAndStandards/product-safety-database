require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Business export", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, :with_test_queue_adapter, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:business) { create(:business) }
  let(:investigation) { create(:allegation) }

  before do
    create(:investigation_business, business: business, investigation: investigation)
    user.roles.create!(name: "psd_admin")
    sign_in(user)
    allow(BusinessExportJob).to receive(:perform_later) do
      BusinessExportJob.new.perform(BusinessExport.last)
    end
  end

  scenario "allows the user to generate an export" do
    Investigation.import force: true, refresh: :wait_for
    Business.import force: true, refresh: :wait_for
    visit businesses_path

    click_link "Export as spreadsheet"
    expect(page).to have_content "Your business export is being prepared. You will receive an email when your export is ready to download."

    perform_enqueued_jobs

    expect(BusinessExport.count).to eq 1
    expect(BusinessExport.first.export_file.attached?).to eq true

    business_export_email = delivered_emails.last
    expect(business_export_email.action_name).to eq "business_export"
    expect(business_export_email.personalization[:name]).to eq user.name
    expect(business_export_email.personalization[:download_export_url]).to eq business_export_url(BusinessExport.first.id)
  end
end
