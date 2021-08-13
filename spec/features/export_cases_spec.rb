require "rails_helper"
require "sidekiq/testing"

RSpec.feature "Case export", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, :with_test_queue_adapter, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }

  before do
    create_list(:allegation, 10, creator: user)
    user.roles.create!(name: "psd_admin")
    sign_in(user)
    allow(CaseExportJob).to receive(:perform_later) do
      CaseExportJob.new.perform(Investigation.pluck(:id), CaseExport.last.id, user)
    end
  end

  scenario "allows the user to generate an export" do
    Product.import refresh: :wait_for
    visit investigations_path

    click_link "Export as spreadsheet"
    expect(page).to have_content "Your case export is being prepared. You will receive an email when your export is ready to download."

    perform_enqueued_jobs

    expect(CaseExport.count).to eq 1
    expect(CaseExport.first.export_file.attached?).to eq true

    case_export_email = delivered_emails.last
    expect(case_export_email.action_name).to eq "case_export"
    expect(case_export_email.personalization[:name]).to eq user.name
    expect(case_export_email.personalization[:download_export_url]).to eq case_export_url(CaseExport.first.id)
  end
end
