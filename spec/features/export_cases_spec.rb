require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Case export", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create :user, :psd_admin, :activated }
  let(:export) { CaseExport.find_by(user: user) }
  let(:email) { delivered_emails.last }

  before do
    create_list(:allegation, 10, creator: user)
    Investigation.import force: true, refresh: :wait_for

    sign_in(user)
  end

  scenario "with no filters selected" do
    visit investigations_path

    click_link "CSV file"
    expect(page).to have_content "Your case export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "case_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq case_export_url(export)
  end
end
