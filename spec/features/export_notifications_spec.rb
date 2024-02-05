require "rails_helper"
require "sidekiq/testing"

RSpec.feature "notification export", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
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

  let!(:enquiry_coronavirus) { create(:enquiry, coronavirus_related: true, creator: user) }
  let!(:allegation_serious) { create(:allegation, risk_level: "serious", description: "Serious risk case", creator: other_user_same_team) }
  let!(:allegation_other_team) { create(:allegation, creator: other_user, read_only_teams: [user.team]) }
  let!(:allegation_closed) { create(:allegation, :closed, creator: user) }

  before do
    Investigation.reindex
    sign_in(user)
    visit investigations_path
    expand_filters
  end

  scenario "with no filters selected" do
    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).to have_text allegation_serious.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id

    click_link "XLSX (spreadsheet)"
    expect(page).to have_content "Your notification export is being prepared. You will receive an email when your export is ready to download."

    expect(email.action_name).to eq "notification_export"
    expect(email.personalization[:name]).to eq user.name
    expect(email.personalization[:download_export_url]).to eq notification_export_url(export)

    expect(spreadsheet.last_row).to eq(4)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
    expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
    expect(spreadsheet.cell(4, 1)).to eq(allegation_other_team.pretty_id)
  end

  scenario "with search query" do
    fill_in "Search", with: "Serious"
    click_button "Submit search"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id
    expect(page).to have_text allegation_serious.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_serious.pretty_id)
  end

  scenario "with filtering on risk level" do
    choose "Serious and high risk"
    click_button "Apply"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id
    expect(page).to have_text allegation_serious.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_serious.pretty_id)
  end

  scenario "with filtering on notification type" do
    choose "Enquiry"
    click_button "Apply"

    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
  end

  scenario "with filtering on notification status" do
    choose "Closed"
    click_button "Apply"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id
    expect(page).to have_text allegation_closed.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_closed.pretty_id)
  end

  scenario "with filtering on notifications created by current user" do
    within_fieldset "Created by" do
      choose "Me"
    end

    click_button "Apply"

    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
  end

  scenario "with filtering on notifications created by another user on the same team" do
    within_fieldset "Created by" do
      choose "Me and my team"
    end

    click_button "Apply"

    expect(page).to have_text allegation_serious.pretty_id
    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(3)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
    expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
  end

  scenario "with filtering on notifications created by another user or team" do
    within_fieldset "Created by" do
      choose "Others"
      select other_user.name
    end

    click_button "Apply"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_other_team.pretty_id)
  end

  scenario "with filtering on notifications with the user's team added to the notifications" do
    within_fieldset "Teams added to notifications" do
      choose "My team"
    end

    click_button "Apply"

    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(4)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
    expect(spreadsheet.cell(3, 1)).to eq(allegation_serious.pretty_id)
    expect(spreadsheet.cell(4, 1)).to eq(allegation_other_team.pretty_id)
  end

  scenario "with filtering on notifications with another user or team added to the notifications" do
    within_fieldset "Teams added to notifications" do
      choose "Other"
      select other_user.team.name
    end

    click_button "Apply"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_other_team.pretty_id)
  end

  scenario "with filtering on notifications owned by the user" do
    within_fieldset "Notification owner" do
      choose "Me"
    end

    click_button "Apply"

    expect(page).to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).not_to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(enquiry_coronavirus.pretty_id)
  end

  scenario "with filtering on notifications owned by another team" do
    within_fieldset "Notification owner" do
      choose "Others"
      select other_user.team.name
    end

    click_button "Apply"

    expect(page).not_to have_text enquiry_coronavirus.pretty_id
    expect(page).not_to have_text allegation_serious.pretty_id
    expect(page).not_to have_text allegation_closed.pretty_id
    expect(page).to have_text allegation_other_team.pretty_id

    click_link "XLSX (spreadsheet)"

    expect(spreadsheet.last_row).to eq(2)
    expect(spreadsheet.cell(2, 1)).to eq(allegation_other_team.pretty_id)
  end

  context "when search does not return any results" do
    it "does not show the export link" do
      expand_help_details
      expect(page).to have_link("XLSX (spreadsheet)")

      fill_in "Search", with: "unsuccesfulsearchquery"
      click_button "Submit search"

      expand_help_details
      expect(page).not_to have_link("XLSX (spreadsheet)")
    end
  end

  def expand_filters
    find("#filter-details").click
  end

  def expand_help_details
    first(".govuk-details__summary").click
  end
end
