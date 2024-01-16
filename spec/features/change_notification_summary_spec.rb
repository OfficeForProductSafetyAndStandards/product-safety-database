RSpec.feature "Changing the case summary", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:notification) { create(:project, creator: user) }
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  scenario "user on same team as case owner" do
    sign_in user
    visit investigation_path(notification)

    click_link "Edit the summary"

    expect_to_be_on_case_summary_edit_page(case_id: notification.pretty_id)
    expect_to_have_notification_breadcrumbs
    fill_in "Edit the summary", with: ""
    click_on "Save"

    expect_to_be_on_case_page(case_id: notification.pretty_id)

    click_link "Edit the summary"

    expect_to_be_on_case_summary_edit_page(case_id: notification.pretty_id)
    expect_to_have_notification_breadcrumbs
    fill_in "Edit the summary", with: "new summary"
    click_on "Save"

    expect_to_be_on_case_page(case_id: notification.pretty_id)
    expect(page).to have_css("span", text: "new summary")

    click_link "Activity"
    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
    expect(page).to have_text("Notification summary updated")
  end

  scenario "user from other team cannot edit summary" do
    sign_in other_user
    visit investigation_path(notification)
    expect(page).not_to have_link("Edit the summary")
  end
end
