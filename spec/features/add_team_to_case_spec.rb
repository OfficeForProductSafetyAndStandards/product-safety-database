require "rails_helper"

RSpec.feature "Adding a team to a case", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  include_context "with read only team and user"
  let(:team)           { create(:team, name: "Southampton Trading Standards", team_recipient_email: "enquiries@southampton.gov.uk") }
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, read_only_teams: read_only_team, creator: user) }
  let!(:deleted_team)  { create(:team, :deleted) }

  before do
    read_only_team.update!(name: "Birmingham Trading Standards")
    team
  end

  scenario "when signed in as an owner of the case" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Change the teams added"

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner", creator: true },
      { team_name: "Birmingham Trading Standards", permission_level: "View full case" }
    ])

    click_link "Add a team to the case"

    expect_to_be_on_add_team_to_case_page(case_id: investigation.pretty_id)

    click_button "Add team to this case"

    # Validation errors
    expect(page).to have_title("Error: Add a team to the case")
    expect(page).to have_selector("a", text: "Select a team to add to the case")
    expect(page).to have_selector("a", text: "Select the permission level the team should have")
    expect(page).to have_selector("a", text: "Select whether you want to include a message")

    # Check deleted teams are not listed
    expect(page).to have_select("Choose team", with_options: [team.name])
    expect(page).not_to have_select("Choose team", with_options: [deleted_team.name])

    select "Southampton Trading Standards", from: "Choose team"
    choose "Edit full case"
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

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards",  permission_level: "Case owner", creator: true },
      { team_name: "Southampton Trading Standards", permission_level: "Edit full case" },
      { team_name: "Birmingham Trading Standards",  permission_level: "View full case" }
    ])

    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq("enquiries@southampton.gov.uk")
    expect(notification_email.personalization[:updater_name]).to eq("Bob Jones (Portsmouth Trading Standards)")
    expect(notification_email.personalization[:optional_message]).to eq("Message from Bob Jones (Portsmouth Trading Standards):\n\n^ Thanks for collaborating on this case with us.")
    expect(notification_email.personalization[:investigation_url]).to end_with("/cases/#{investigation.pretty_id}")

    click_link "Back"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added", value: "Portsmouth Trading Standards Birmingham Trading Standards Southampton Trading Standards")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Southampton Trading Standards added to allegation")
    expect(page).to have_text("Team added by Bob Jones")
    expect(page).to have_text("Permission level given: edit full case.")
    expect(page).to have_text("Thanks for collaborating on this case with us.")
  end
end
