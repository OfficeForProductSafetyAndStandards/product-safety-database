require "rails_helper"
require "sidekiq/testing"

RSpec.describe "notification export", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user_team) { create :team, name: "User Team" }
  let(:user) { create :user, :all_data_exporter, :opss_user, :activated, team: user_team, organisation: user_team.organisation }
  let(:other_user_same_team) { create :user, :activated, team: user_team, organisation: user_team.organisation }
  let(:other_user_team) { create :team, name: "Other User Team" }
  let(:other_user) { create :user, :activated, team: other_user_team, organisation: other_user_team.organisation }
  let(:email) { delivered_emails.last }
  let(:export) { NotificationExport.find_by(user:) }
  let(:spreadsheet) do
    export.export_file.blob.open do |file|
      Roo::Excelx.new(file).sheet("Notifications")
    end
  end

  let(:product) do
    create(:product,
           name: "MyBrand washing machine",
           category: "kitchen appliances",
           product_code: "W2020-10/1")
  end

  let!(:investigation) { create(:notification, products: [product], user_title: "MyBrand washing machine", reported_reason: "unsafe") }
  let!(:allegation_serious) { create(:allegation, risk_level: "serious", description: "Serious risk case", creator: other_user_same_team) }
  let!(:allegation_other_team) { create(:allegation, creator: other_user, read_only_teams: [user.team]) }
  let!(:allegation_closed) { create(:allegation, :closed, creator: user) }

  before do
    Investigation.reindex
    sign_in(user)
    visit "/notifications"
  end

  it "with no filters selected" do
    expect(page).to have_text investigation.pretty_id
    expect(page).to have_text allegation_serious.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id
    expect(page).to have_text allegation_closed.pretty_id

    click_link "XLSX (spreadsheet)"
    expect(page).to have_content "Your notification export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "notification_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq notification_export_url(export)

    expect(spreadsheet.last_row).to eq(5)
    expect(spreadsheet.cell(2, 1)).to eq(investigation.pretty_id)
    expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
    expect(spreadsheet.cell(4, 1)).to eq(allegation_other_team.pretty_id)
    expect(spreadsheet.cell(5, 1)).to eq(allegation_closed.pretty_id)
  end

  it "with search query" do
    fill_in "Search", with: "Serious"
    click_button "Submit search"

    expect(page).not_to have_text allegation_other_team.pretty_id
    expect(page).to have_text allegation_serious.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_serious.pretty_id)
  end

  context "when search does not return any results" do
    it "does not show the export link" do
      expect(page).to have_link("XLSX (spreadsheet)")

      fill_in "Search", with: "unsuccesfulsearchquery"
      click_button "Submit search"

      expect(page).not_to have_link("XLSX (spreadsheet)")
    end
  end

  context "when filtering by notification type" do
    it "shows the correct notifications for that type" do
      find("details#case-type").click
      check "Notification"
      check "Allegation"
      check "Project"
      check "Enquiry"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_text investigation.pretty_id
      expect(page).to have_text allegation_serious.pretty_id
      expect(page).to have_text allegation_other_team.pretty_id
      expect(page).to have_text allegation_closed.pretty_id

      click_link "XLSX (spreadsheet)"
      expect(page).to have_content "Your notification export is being prepared. You will receive an email when your export is ready to download."

      expect(email.action_name).to eq "notification_export"
      expect(email.personalization[:name]).to eq user.name
      expect(email.personalization[:download_export_url]).to eq notification_export_url(export)

      expect(spreadsheet.last_row).to eq(5)
      expect(spreadsheet.cell(2, 1)).to eq(investigation.pretty_id)
      expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
      expect(spreadsheet.cell(4, 1)).to eq(allegation_other_team.pretty_id)
      expect(spreadsheet.cell(5, 1)).to eq(allegation_closed.pretty_id)
    end
  end

  context "when filtering by notification status" do
    it "shows the correct notifications for open status" do
      find("details#case-status").click
      check "Open"
      click_button "Apply"

      expect_to_be_on_notifications_index_page

      expect(page).to have_text investigation.pretty_id
      expect(page).to have_text allegation_serious.pretty_id
      expect(page).to have_text allegation_other_team.pretty_id
      expect(page).not_to have_text allegation_closed.pretty_id

      click_link "XLSX (spreadsheet)"
      expect(page).to have_content "Your notification export is being prepared. You will receive an email when your export is ready to download."

      expect(email.action_name).to eq "notification_export"
      expect(email.personalization[:name]).to eq user.name
      expect(email.personalization[:download_export_url]).to eq notification_export_url(export)

      expect(spreadsheet.last_row).to eq(4)
      expect(spreadsheet.cell(2, 1)).to eq(investigation.pretty_id)
      expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
      expect(spreadsheet.cell(4, 1)).to eq(allegation_other_team.pretty_id)
    end
  end
end
