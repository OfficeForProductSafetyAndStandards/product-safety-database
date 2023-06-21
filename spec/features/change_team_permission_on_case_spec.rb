require "rails_helper"

RSpec.feature "Changing a team's permissions on a case", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:team)           { create(:team, name: "Southampton Trading Standards", team_recipient_email: "enquiries@southampton.gov.uk") }
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user, edit_access_teams: [team]) }

  scenario "removing a team (with validation errors)" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}/teams"

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards",  permission_level: "Case owner", creator: true },
      { team_name: "Southampton Trading Standards", permission_level: "Edit full case" }
    ])

    click_on "Change Southampton Trading Standards’s permission level"

    expect_to_be_on_edit_case_permissions_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    click_button "Update team"

    expect(page).to have_title("Error: #{team.name}")
    expect(page).to have_selector("a", text: "This team already has this permission level. Select a different option or return to the case.")
    expect(page).to have_selector("a", text: "Select whether you want to include a message")
    expect_to_have_case_breadcrumbs

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
      fill_in "Message to the #{team.name}", with: "Thanks for collaborating on this case with us before."
    end

    click_button "Update team"

    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq("enquiries@southampton.gov.uk")
    expect(notification_email.personalization_value(:case_id)).to eq(investigation.pretty_id)
    expect(notification_email.personalization_value(:case_type)).to eq("case")
    expect(notification_email.personalization_value(:case_title)).to eq(investigation.decorate.title)
    expect(notification_email.personalization_value(:updater_name)).to eq("Bob Jones (Portsmouth Trading Standards)")
    expect(notification_email.personalization_value(:optional_message)).to eq("Message from Bob Jones (Portsmouth Trading Standards):\n\n^ Thanks for collaborating on this case with us before.")

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner", creator: true }
    ])

    expect_teams_tables_not_to_contain([
      { team_name: "Southampton Trading Standards" }
    ])

    click_link investigation.pretty_id
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added", value: "Portsmouth Trading Standards")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Southampton Trading Standards removed from case")
    expect(page).to have_text("Team removed by Bob Jones")
    expect(page).to have_text("Thanks for collaborating on this case with us before.")
  end

  scenario "changing a team from edit to read-only" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}/teams"
    expect_to_be_on_teams_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards",  permission_level: "Case owner", creator: true },
      { team_name: "Southampton Trading Standards", permission_level: "Edit full case" }
    ])

    click_on "Change Southampton Trading Standards’s permission level"

    expect_to_be_on_edit_case_permissions_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    within_fieldset "Permission level" do
      choose "View full case"
    end
    within_fieldset "Do you want to include more information?" do
      choose "Yes, add a message"
    end

    within_fieldset "Do you want to include more information?" do
      fill_in "Message to the #{team.name}", with: "You now have view read only access."
    end

    click_button "Update team"

    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq("enquiries@southampton.gov.uk")
    expect(notification_email.personalization_value(:case_id)).to eq(investigation.pretty_id)
    expect(notification_email.personalization_value(:case_type)).to eq("case")
    expect(notification_email.personalization_value(:case_title)).to eq(investigation.decorate.title)
    expect(notification_email.personalization_value(:updater_name)).to eq("Bob Jones (Portsmouth Trading Standards)")
    expect(notification_email.personalization_value(:optional_message)).to eq("Message from Bob Jones (Portsmouth Trading Standards):\n\n^ You now have view read only access.")
    expect(notification_email.personalization_value(:old_permission)).to eq("edit full case")
    expect(notification_email.personalization_value(:new_permission)).to eq("view full case")

    expect_to_be_on_teams_page(case_id: investigation.pretty_id)
    expect_to_have_case_breadcrumbs

    expect_teams_tables_to_contain([
      { team_name: "Portsmouth Trading Standards", permission_level: "Case owner", creator: true },
      { team_name: "Southampton Trading Standards", permission_level: "View full case" }
    ])

    click_link investigation.pretty_id
    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added", value: "Portsmouth Trading Standards Southampton Trading Standards")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Southampton Trading Standards's case permission level changed")
    expect(page).to have_text("Case permissions updated by Bob Jones")
    expect(page).to have_text("You now have view read only access.")
  end
end
