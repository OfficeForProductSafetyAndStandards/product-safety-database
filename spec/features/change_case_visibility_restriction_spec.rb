require "rails_helper"

RSpec.feature "Change case restriction status", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation) { create(:allegation, creator: user) }

  let(:case_id) { investigation.pretty_id }

  before { sign_in(user) }

  context "when the user is the owner of the case" do
    context "when the case is unrestricted" do
      scenario "user can change the restriction status of the case" do
        visit "/cases/#{case_id}"

        expect_to_be_on_case_page(case_id: case_id)
        expect(page).to have_summary_item(key: "Case restriction", value: "Unrestricted")
        expect(page).to have_link "Change case restriction"
        click_link "Change case restriction"

        expect_to_be_on_case_visiblity_page(case_id: case_id, status: "unrestricted", action: "restrict")

        click_on "Continue"

        expect_to_be_on_change_case_visiblity_page(case_id: case_id, future_status: "restricted", action: "restrict")
        fill_in "Why is the case being restricted?", with: "Restriction reason"
        click_button "Restrict this case"

        expect_to_be_on_case_page(case_id: case_id)
        expect_confirmation_banner("Allegation was restricted")
        expect(page).to have_summary_item(key: "Case restriction", value: "Restricted")
      end
    end

    context "when the case is restricted" do
      before do
        visit "/cases/#{case_id}"
        click_link "Change case restriction"
        click_on "Continue"
        fill_in "Why is the case being restricted?", with: "Restriction reason"
        click_button "Restrict this case"
      end

      scenario "user can change the restriction status of the case" do
        visit "/cases/#{case_id}"

        expect_to_be_on_case_page(case_id: case_id)
        expect(page).to have_summary_item(key: "Case restriction", value: "Restricted")
        expect(page).to have_link "Change case restriction"
        click_link "Change case restriction"

        expect_to_be_on_case_visiblity_page(case_id: case_id, status: "restricted", action: "unrestrict")

        click_on "Continue"

        expect_to_be_on_change_case_visiblity_page(case_id: case_id, future_status: "unrestricted", action: "unrestrict")
        fill_in "Why is the case being unrestricted?", with: "Unrestricted reason"
        click_button "Unrestrict this case"

        expect_to_be_on_case_page(case_id: case_id)
        expect_confirmation_banner("Allegation was unrestricted")
        expect(page).to have_summary_item(key: "Case restriction", value: "Unrestricted")
      end
    end
  end

  context "when the user has read only access" do
    include_context "with read only team and user"
    let(:user) { read_only_user }
    let(:investigation) { create(:allegation, :with_complainant, :restricted, creator: create(:user), read_only_teams: read_only_team) }

    it "the can view restricted details" do
      visit "/cases/#{case_id}"

      expect_to_be_on_case_page(case_id: case_id)
      expect(page).to have_summary_item(key: "Contact details", value: /#{Regexp.escape(investigation.complainant.name)}/)
      expect(page).to have_summary_item(key: "Case restriction", value: "Restricted")
    end
  end

  context "when the user is not the case owner" do
    let(:investigation) { create(:allegation, creator: create(:user)) }

    scenario "user can’t change the restriction status of the case" do
      visit "/cases/#{case_id}"
      expect_to_be_on_case_page(case_id: case_id)
      expect(page).to have_summary_item(key: "Case restriction", value: "Unrestricted")
      expect(page).not_to have_link "Change case restriction"
    end
  end
end
