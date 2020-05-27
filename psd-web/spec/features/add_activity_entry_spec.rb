require "rails_helper"

RSpec.feature "Adding an activity to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let!(:creator_user) { create(:user, :activated, email: "creator@example.com", team: team_without_email, organisation: team_without_email.organisation) }
  let(:team_without_email) { create(:team, team_recipient_email: nil) }

  let(:investigation_owner) { creator_user }
  let(:investigation) { create(:allegation, owner: investigation_owner) }
  let(:commentator_user) { create(:user, :activated) }

  scenario "Picking an activity type" do
    sign_in creator_user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add activity"

    expect(page).to have_content("New activity")

    click_button "Continue"

    expect(page).to have_content("Activity type must not be empty")
  end

  scenario "Assigned user to the case receives activity notifications" do
    sign_in commentator_user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add comment"

    add_comment

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect(page).to have_css(".hmcts-banner", text: "Comment was successfully added.")

    expect(delivered_emails.last.recipient).to eq creator_user.email
    expect(delivered_emails.last.personalization).to include(
      name: creator_user.name,
      subject_text: "Allegation updated",
      update_text: "#{commentator_user.name} (test team) commented on the allegation."
    )
  end

  context "when the case is owned by a team which does not have an email address" do
    let(:investigation_owner) { team_without_email }

    before do
      create(:user, :activated, email: "active@example.com", name: "Active user", team: team_without_email, organisation: team_without_email.organisation)
      create(:user, :inactive, email: "not_activated@example.com", team: team_without_email, organisation: team_without_email.organisation)
      create(:user, :activated, :deleted, email: "deleted@example.com", team: team_without_email, organisation: team_without_email.organisation)
    end

    scenario "case updates send a notification to the team's active users" do
      sign_in commentator_user

      visit "/cases/#{investigation.pretty_id}"
      click_link "Add comment"

      add_comment

      expect_to_be_on_case_page(case_id: investigation.pretty_id)
      expect(page).to have_css(".hmcts-banner", text: "Comment was successfully added.")

      expect(delivered_emails.map(&:recipient).uniq.sort).to eq ["active@example.com", "creator@example.com"]

      delivered_emails.each do |email|
        expect(email.personalization).to include(
          subject_text: "Allegation updated",
          update_text: "#{commentator_user.name} (test team) commented on the allegation."
        )
      end
    end
  end

  def add_comment
    expect(page).to have_css("h1", text: "Add comment")

    fill_in "body", with: Faker::Lorem.sentence
    click_button "Continue"
  end
end
