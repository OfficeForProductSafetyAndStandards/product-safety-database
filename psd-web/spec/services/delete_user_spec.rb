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

    context "when given an user that does not belong to any team" do
      subject(:delete_call) do
        described_class.call(user: build_stubbed(:user, teams: []))
      end

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "User does not belong to a team so their investigations can't be reassigned"
      end
    end

    context "when given an user that is already deleted" do
      subject(:delete_call) { described_class.call(user: user) }

      let(:user) { create(:user, :deleted) }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "User already deleted"
      end
    end

    context "when given an user that is not already deleted" do
      subject(:delete_call) { described_class.call(user: user) }

      let(:user) { create(:user_with_teams, teams_count: 2) }
      let(:user_first_team) { user.teams.first }
      let!(:allegation) { create(:allegation, assignable: user) }
      let!(:enquiry) { create(:enquiry, assignable: user) }
      let!(:project) { create(:project, assignable: user) }

      it "succeeds" do
        expect(delete_call).to be_a_success
      end

      # rubocop:disable RSpec/ExampleLength
      it "sets the user deleted timestamp" do
        freeze_time do
          expect {
            delete_call
            user.reload
          }.to change(user, :deleted_at).from(nil).to(Time.current)
        end
      end

      it "reassigns user cases to their first team" do
        expect {
          delete_call
          allegation.reload
          enquiry.reload
          project.reload
        }.to change(allegation, :assignable).from(user).to(user_first_team)
         .and change(enquiry, :assignable).from(user).to(user_first_team)
         .and change(project, :assignable).from(user).to(user_first_team)
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/MultipleExpectations
      it "registers the assignable automatic update in the investigations activity log" do
        update_assignable_activities = Activity.where(type: "AuditActivity::Investigation::AutomaticallyReassign")

        expect { delete_call }.to change(update_assignable_activities, :count).by(3)

        update_assignable_activities.last(3).each do |activity|
          expect(activity.title).to include "assigned to #{user_first_team.display_name}"
        end
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "does not send notifications to the user or the team" do
        expect { delete_call }.not_to change(delivered_emails, :count)
      end
    end
  end
end
