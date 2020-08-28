require "rails_helper"

RSpec.feature "Changing the case summary", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:investigation) { create(:project, creator: user) }
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  scenario "user on same team as case owner" do
    sign_in user
    visit investigation_path(investigation)

    click_link "Change summary"

    expect_to_be_on_case_summary_edit_page(case_id: investigation.pretty_id)
    fill_in "Edit summary", with: ""
    click_on "Update summary"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Enter the case summary"

    fill_in "Edit summary", with: "new summary"
    click_on "Update summary"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_css("p", text: "new summary")

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_text("Project summary updated")
  end

  scenario "user from other team cannot edit summary" do
    sign_in other_user
    visit investigation_path(investigation)
    expect(page).not_to have_link("Change summary")
  end
end
