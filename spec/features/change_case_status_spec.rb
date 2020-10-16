require "rails_helper"

RSpec.feature "Changing the status of a case", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let!(:investigation) { create(:allegation, creator: creator_user, is_closed: false) }
  let(:user) { create(:user, :activated, name: "Jane Jones") }
  let(:creator_user) { create(:user, email: "test@example.com") }

  before do
    ChangeCaseOwner.call!(investigation: investigation, owner: user.team, user: user)
    delivered_emails.clear
  end

  scenario "Closing a case" do
    sign_in user
    visit investigation_path(investigation)

    click_link "Change status"
    expect_to_be_on_change_case_status_page(case_id: investigation.pretty_id)

    # Expect existing status to be pre-selected
    within_fieldset "Status" do
      expect(page).to have_checked_field("Open")
      expect(page).to have_unchecked_field("Closed")
    end

    # Change status to closed, and add a reason
    within_fieldset "Status" do
      choose "Closed"
    end
    fill_in "Why are you changing the status?", with: "Case has been resolved."

    click_button "Save"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Allegation was successfully updated")
    expect(page).to have_summary_item(key: "Status", value: "Closed")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_text("Allegation closed")
    expect(page).to have_text("Case has been resolved.")

    expect(delivered_emails).to have_email(
      to: "test@example.com",
      subject: "Allegation was closed",
      with_text: "Allegation was closed by Jane Jones"
    )
  end
end
