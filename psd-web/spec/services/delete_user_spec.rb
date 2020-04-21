require "rails_helper"

RSpec.describe DeleteUser, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  describe ".call" do
    context "with no parameters" do
      subject(:delete_call) { described_class.call }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "No user supplied"
      end
    end

    context "when given an user" do
      subject(:delete_call) { described_class.call(user: user) }

      let(:user) { create(:user_with_teams, teams_count: 2) }
      let(:user_first_team) { user.teams.first }
      let!(:allegation) { create(:allegation, assignee: user) }
      let!(:enquiry) { create(:enquiry, assignee: user) }
      let!(:project) { create(:project, assignee: user) }

      it "succeeds" do
        expect(delete_call).to be_a_success
      end

      it "sets the user as deleted" do
        expect {
          delete_call
          user.reload
        }.to change(user, :deleted).from(false).to(true)
      end

      # rubocop:disable RSpec/ExampleLength
      it "reassigns user cases to their first team" do
        expect {
          delete_call
          allegation.reload
          enquiry.reload
          project.reload
        }.to change(allegation, :assignee).from(user).to(user_first_team)
         .and change(enquiry, :assignee).from(user).to(user_first_team)
         .and change(project, :assignee).from(user).to(user_first_team)
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/MultipleExpectations
      it "registers the user deletion in their assigned investigations activity log" do
        delete_assignee_activities = Activity.where(type: "AuditActivity::Investigation::DeleteAssignee")

        expect { delete_call }.to change(delete_assignee_activities, :count).by(3)

        delete_assignee_activities.last(3).each do |activity|
          expect(activity.title).to start_with "User #{user.name} (#{user.organisation.name}) deleted"
        end
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "does not send notifications to the user or the team" do
        expect { delete_call }.not_to change(delivered_emails, :count)
      end
    end
  end
end
