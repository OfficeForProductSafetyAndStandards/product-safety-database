require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Business export", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create :user, :psd_admin, :activated }
  let(:export) { BusinessExport.find_by(user: user) }
  let(:email) { delivered_emails.last }

  before do
    create(:investigation_business)
    Investigation.import force: true, refresh: :wait_for
    Business.import force: true, refresh: :wait_for

    sign_in(user)
  end

  scenario "with no filters selected" do
    visit businesses_path

    click_link "Export as spreadsheet"
    expect(page).to have_content "Your business export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "business_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq business_export_url(export)
  end
end
