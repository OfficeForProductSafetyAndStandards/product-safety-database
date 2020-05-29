require "rails_helper"

RSpec.feature "Case permissions management", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) do
    create(
      :user,
      :activated,
      team: create(:team, name: "Portsmouth Trading Standards"),
      name: "Bob Jones"
    )
  end

  let(:investigation) do
    create(
      :allegation,
      owner: user
    )
  end

  let(:team) do
    create(:team, name: "Southampton Trading Standards", team_recipient_email: "enquiries@southampton.gov.uk")
  end

  before do
    team
  end

  scenario "Adding a team to a case (with validation errors)" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Change teams added to the case"

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner" }
    ])

    click_link "Add a team to the case"

    expect_to_be_on_add_team_to_case_page(case_id: investigation.pretty_id)

    click_button "Add team to this case"

    # Validation errors
    expect(page).to have_title("Error: Add a team to the case")
    expect(page).to have_selector("a", text: "Select a team to add to the case")
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

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner" },
      { team_name: "Southampton Trading Standards", permission_level: "Edit full case" }
    ])

    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq("enquiries@southampton.gov.uk")
    expect(notification_email.personalization[:updater_name]).to eq("Bob Jones (Portsmouth Trading Standards)")
    expect(notification_email.personalization[:optional_message]).to eq("Message from Bob Jones (Portsmouth Trading Standards):\n\n^ Thanks for collaborating on this case with us.")
    expect(notification_email.personalization[:investigation_url]).to end_with("/cases/#{investigation.pretty_id}")

    click_link "Back"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added to case", value: "Portsmouth Trading Standards Southampton Trading Standards")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Southampton Trading Standards added to allegation")
    expect(page).to have_text("Team added by Bob Jones")
    expect(page).to have_text("Thanks for collaborating on this case with us.")
  end

  scenario "Remove a team from a case (with validation errors)" do
    sign_in user
    create(:collaboration_edit_access, investigation: investigation, collaborator: team)

    visit "/cases/#{investigation.pretty_id}"

    click_link "Change teams added to the case"

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner" },
      { team_name: "Southampton Trading Standards", permission_level: "Edit full case" }
    ])

    click_on "Change"

    expect_to_be_on_edit_case_permissions_page(case_id: investigation.pretty_id)

    click_button "Update team"

    expect(page).to have_title("Error: #{team.name}")
    expect(page).to have_selector("a", text: "This team already has this permission level. Select a different option or return to the case.")
    expect(page).to have_selector("a", text: "Select whether you want to include a message")

    within_fieldset "Permission level" do
      choose "Remove #{team.name} from the case"
    end
    within_fieldset "Do you want to include more information?" do
      choose "Yes, add a message"
    end

    click_button "Update team"

    expect(page).to have_title("Error: #{team.name}")
    expect(page).to have_selector("a", text: "Enter a message to the team")

    within_fieldset "Do you want to include more information?" do
      fill_in "Message to the #{team.name}", with: "Thanks for collaborating on this case with us."
    end

    click_button "Update team"

    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq("enquiries@southampton.gov.uk")
    expect(notification_email.personalization_value(:case_id)).to eq(investigation.pretty_id)
    expect(notification_email.personalization_value(:case_type)).to eq("allegation")
    expect(notification_email.personalization_value(:case_title)).to eq(investigation.decorate.title)
    expect(notification_email.personalization_value(:updater_name)).to eq("Bob Jones (Portsmouth Trading Standards)")
    expect(notification_email.personalization_value(:optional_message)).to eq("Message from Bob Jones (Portsmouth Trading Standards):\n\n^ Thanks for collaborating on this case with us.")

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner" }
    ])

    expect_teams_tables_not_to_contain([
      { team_name: "Southampton Trading Standards" }
    ])
  end
end
