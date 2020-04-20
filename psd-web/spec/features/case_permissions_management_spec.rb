require "rails_helper"

RSpec.feature "Case permissions management", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) {
    create(:user,
           :activated,
           teams: [create(:team, name: "Portsmouth Trading Standards")],
           name: "Bob Jones")
  }

  let(:investigation) {
    create(:investigation,
           assignee: user)
  }

  before do
    create(:team, name: "Southampton Trading Standards", team_recipient_email: "enquiries@southampton.gov.uk")
  end

  scenario "Adding a team to a case (with validation errors)" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add team"

    expect_to_be_on_add_team_to_case_page(case_id: investigation.pretty_id)

    click_button "Add team to this case"

    # Validation errors
    expect(page).to have_title("Error: Add a team to the case")
    expect(page).to have_selector("a", text: "Select a team")
    expect(page).to have_selector("a", text: "Select whether you want to include a message")

    select "Southampton Trading Standards", from: "Choose team"
    within_fieldset "Do you want to include instructions or more information?" do
      choose "Yes, add a message"
    end

    click_button "Add team to this case"

    # Validation errors
    expect(page).to have_title("Error: Add a team to the case")
    expect(page).to have_selector("a", text: "Enter a message to the team")

    within_fieldset "Do you want to include instructions or more information?" do
      fill_in "Message to the team", with: "Thanks for collaborating on this case with us."
    end

    click_button "Add team to this case"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added to case", value: "Southampton Trading Standards Portsmouth Trading Standards")


    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eql("enquiries@southampton.gov.uk")
    expect(notification_email.personalization[:updater_name]).to eql("Bob Jones")
    expect(notification_email.personalization[:optional_message]).to eql("^ Thanks for collaborating on this case with us.")
    expect(notification_email.personalization[:investigation_url]).to end_with("/cases/#{investigation.pretty_id}")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Southampton Trading Standards added to allegation")
    expect(page).to have_text("Team added by Bob Jones")
    expect(page).to have_text("Thanks for collaborating on this case with us.")
  end

private

  def expect_to_be_on_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}")
    expect(page).to have_selector("h1", text: "Overview")
  end

  def expect_to_be_on_add_team_to_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/teams/add")
    expect(page).to have_selector("h1", text: "Add a team to the case")
  end

  def expect_to_be_on_case_activity_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/activity")
    expect(page).to have_selector("h1", text: "Activity")
  end
end
