require "rails_helper"

RSpec.feature "Adding an activity to a case", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let!(:creator_user) { create(:user, :activated, email: "creator@example.com", team: team_without_email, organisation: team_without_email.organisation) }
  let(:team_without_email) { create(:team, team_recipient_email: nil) }

  let(:investigation_owner) { creator_user }
  let(:commentator_user) { create(:user, :activated).decorate }

  # Create the case up front and clear the case created email so we can test update email functionality
  let!(:investigation) { create(:allegation, creator: creator_user, edit_access_teams: commentator_user.team) }

  before { delivered_emails.clear }

  scenario "Assigned user to the case receives activity notifications" do
    sign_in commentator_user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add a comment"

    add_comment

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_confirmation_banner("The comment was successfully added")

    expect(delivered_emails.last.recipient).to eq creator_user.email
    expect(delivered_emails.last.personalization).to include(
      name: creator_user.name,
      subject_text: "Case updated",
      update_text: "#{commentator_user.name} (#{commentator_user.team.display_name(viewer: creator_user)}) commented on the case."
    )
  end

  context "when the case is owned by a team which does not have an email address" do
    let(:investigation_owner) { team_without_email }

    before do
      create(:user, :activated, email: "active@example.com", name: "Active user", team: team_without_email, organisation: team_without_email.organisation)
      create(:user, :inactive, email: "not_activated@example.com", team: team_without_email, organisation: team_without_email.organisation)
      create(:user, :activated, :deleted, email: "deleted@example.com", team: team_without_email, organisation: team_without_email.organisation)

      ChangeCaseOwner.call!(investigation:, owner: investigation_owner, user: creator_user, old_owner: creator_user)
      delivered_emails.clear
    end

    scenario "case updates send a notification to the team's active users" do
      sign_in commentator_user

      visit "/cases/#{investigation.pretty_id}"
      click_link "Add a comment"

      add_comment

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_confirmation_banner("The comment was successfully added")

      expect(delivered_emails.map(&:recipient).uniq.sort).to eq ["active@example.com", "creator@example.com"]

      delivered_emails.each do |email|
        expect(email.personalization).to include(
          subject_text: "Case updated",
          update_text: "#{commentator_user.name} (#{commentator_user.team.display_name(viewer: creator_user)}) commented on the case."
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
