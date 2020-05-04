require "rails_helper"

RSpec.feature "Adding an activity to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:creator_user) { create(:user, :activated, email: "creator@example.com") }
  let(:investigation) { create(:investigation, assignable: creator_user) }
  let(:investigation_path) { "/cases/#{investigation.pretty_id}" }

  scenario "Picking an activity type" do
    sign_in creator_user

    visit investigation_path

    click_link "Add activity"

    expect(page).to have_content("New activity")

    click_button "Continue"

    expect(page).to have_content("Activity type must not be empty")
  end

  scenario "Assigned user to the case receives activity notifications" do
    commentator_user = create(:user, :activated)

    sign_in commentator_user

    add_comment_to_case

    expect(page).to have_current_path(investigation_path)
    expect(page).to have_css(".hmcts-banner", text: "Comment was successfully added.")
    expect(delivered_emails.last.recipient).to eq creator_user.email
    expect(delivered_emails.last.personalization).to include(
      name: creator_user.name,
      subject_text: "Allegation updated",
      update_text: "#{commentator_user.name} (test organisation) commented on the allegation."
    )
  end

  scenario "Updates on cases assigned to teams without team email send a notification to their active users" do
    team_without_email = create(:team, team_recipient_email: nil)
    active_user = create(:user, :activated, email: "active@example.com", teams: [team_without_email])
    commentator_user = create(:user, :activated)

    create(:user, :inactive, email: "not_activated@example.com", teams: [team_without_email])
    create(:user, :activated, :deleted, email: "deleted@example.com", teams: [team_without_email])
    investigation.update_attribute(:assignable, team_without_email)

    sign_in commentator_user

    add_comment_to_case

    expect(page).to have_current_path(investigation_path)
    expect(page).to have_css(".hmcts-banner", text: "Comment was successfully added.")
    expect(delivered_emails.map(&:recipient).uniq).to eq ["creator@example.com", "active@example.com"]
    expect(delivered_emails.last.personalization).to include(
      name: active_user.name,
      subject_text: "Allegation updated",
      update_text: "#{commentator_user.name} (test organisation) commented on the allegation."
    )
  end

  def add_comment_to_case
    visit investigation_path

    click_link "Add activity"

    expect(page).to have_css("h1", text: "New activity")

    choose "Add a comment"
    click_button "Continue"


    expect(page).to have_css("h1", text: "Add comment")

    fill_in "body", with: Faker::Lorem.sentence
    click_button "Continue"
  end
end
