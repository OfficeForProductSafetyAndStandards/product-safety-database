require "rails_helper"
RSpec.feature "Manage supporting information", :with_stubbed_antivirus, :with_stubbed_mailer do
  include_context "with read only team and user"
  let(:user)           { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation)  { create(:allegation, :with_document, creator: user, read_only_teams: read_only_team) }

  include_context "with all types of supporting information"

  context "when the team from the user viewing the information owns the investigation" do
    scenario "listing supporting information" do
      sign_in read_only_user
      visit "/cases/#{investigation.pretty_id}"
      click_on "Supporting information (6)"
      expect_to_view_supporting_information_sections(can_view_protected_details: true)
      expect_to_have_notification_breadcrumbs

      sign_out
      sign_in user
      visit "/cases/#{investigation.pretty_id}"
      click_on "Supporting information (6)"
      expect_to_view_supporting_information_sections(can_view_protected_details: true)
      expect_to_have_notification_breadcrumbs
    end
  end

  context "when the team from the user viewing the information does not own the investigation" do
    scenario "listing supporting information" do
      sign_in other_user
      visit "/cases/#{investigation.pretty_id}"
      click_on "Supporting information (6)"
      expect_to_view_supporting_information_sections(can_view_protected_details: false)
      expect_to_have_notification_breadcrumbs
    end
  end
end
