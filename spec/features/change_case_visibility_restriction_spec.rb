require "rails_helper"

RSpec.feature "Change notification restriction status", :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:case_id) { investigation.pretty_id }

  before { sign_in(user) }

  context "when the user is the owner of the notification" do
    context "when the notification is unrestricted" do
      let(:investigation) { create(:allegation, creator: user) }

      scenario "user cannot make the notification restricted" do
        visit "/cases/#{case_id}"

        expect_to_be_on_case_page(case_id:)
        expect(page).not_to have_text "Notification restriction"
      end

      scenario "user cannot direct browser to the change notification restriction page" do
        visit "/cases/#{case_id}/visibility"

        # The case cannot be made restricted, so expect a 404
        expect(page).to have_http_status(:not_found)
        expect(page).to have_text("Page not found")
      end
    end

    context "when the case is restricted" do
      let(:investigation) { create(:allegation, :restricted, creator: user) }

      scenario "user can change the restriction status of the notification" do
        visit "/cases/#{case_id}"

        expect_to_be_on_case_page(case_id:)
        expect(page).to have_summary_item(key: "Notification restriction", value: "This notification is Restricted")
        expect(page).to have_link "Change the notification restriction"
        click_link "Change the notification restriction"

        expect_to_be_on_case_visiblity_page(case_id:, status: "restricted", action: "unrestrict")
        expect_to_have_notification_breadcrumbs

        click_on "Continue"

        expect_to_be_on_change_case_visiblity_page(case_id:, future_status: "unrestricted", action: "unrestrict")
        expect_to_have_notification_breadcrumbs
        fill_in "Why is the notification being unrestricted?", with: "Unrestricted reason"
        click_button "Unrestrict this notification"

        # Now back on the case page, the user cannot see the restriction status
        expect_to_be_on_case_page(case_id:)
        expect_confirmation_banner("Notification was unrestricted")
        expect(page).not_to have_text "Notification restriction"

        click_link "Activity"
        expect(page).to have_css("h3", text: "notification unrestricted")
        expect(page).to have_css("p", text: "Unrestricted reason")
      end
    end
  end

  context "when the user has read only access" do
    include_context "with read only team and user"
    let(:user) { read_only_user }
    let(:investigation) { create(:allegation, :with_complainant, :restricted, creator: create(:user), read_only_teams: read_only_team) }

    it "the can view restricted details" do
      visit "/cases/#{case_id}"

      expect_to_be_on_case_page(case_id:)
      expect(page).to have_summary_item(key: "Notification restriction", value: "This notification is Restricted")
    end
  end

  context "when the user is not the notification owner" do
    let(:investigation) { create(:allegation, creator: create(:user)) }

    scenario "user can't change the restriction status of the notification" do
      visit "/cases/#{case_id}"

      expect_to_be_on_case_page(case_id:)
      expect(page).not_to have_link "Change the notification restriction"
    end
  end
end
