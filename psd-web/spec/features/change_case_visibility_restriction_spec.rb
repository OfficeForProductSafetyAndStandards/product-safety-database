require "rails_helper"

RSpec.feature "Change case restriction status", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) do
    create(
      :user,
      :activated,
      team: create(:team, name: "Portsmouth Trading Standards"),
      name: "Bob Jones"
    )
  end

  let(:case_id) { investigation.pretty_id }

  before do
    sign_in(user)
  end

  context "when the user is the owner of the case" do
    let(:investigation) do
      create(
        :allegation,
        creator: user
      )
    end

    scenario "user can change the restriction status of the case" do
      visit "/cases/#{case_id}"

      expect_to_be_on_case_page(case_id: case_id)
      expect(page).to have_summary_item(key: "Case restriction", value: "Unrestricted")
      expect(page).to have_link "Change case restriction"
      click_link "Change case restriction"

      expect_to_be_on_case_visiblity_page(case_id: case_id)

      choose "Restricted for legal privilege"
      fill_in "Comment / rationale", with: "Restriction reason"
      click_button "Save"

      expect_to_be_on_case_page(case_id: case_id)
      expect_confirmation_banner("Allegation was successfully updated")
      expect(page).to have_summary_item(key: "Case restriction", value: "Restricted")
    end
  end

  context "when the user is not the case owner" do
    let(:investigation) do
      create(
        :allegation,
        creator: create(:user)
      )
    end

    scenario "user can’t change the restriction status of the case" do
      visit "/cases/#{case_id}"
      expect_to_be_on_case_page(case_id: case_id)
      expect(page).to have_summary_item(key: "Case restriction", value: "Unrestricted")
      expect(page).not_to have_link "Change case restriction"
    end
  end
end
