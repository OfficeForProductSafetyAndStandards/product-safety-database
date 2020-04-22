require "rails_helper"

RSpec.describe AddTeamToAnInvestigation, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  describe ".call" do
    context "with required parameters" do
      let(:investigation) { create(:allegation) }
      let(:user) { create(:user) }
      let(:team) { create(:team, name: "Testing team") }
      let(:message) { "Thanks for collaborating." }

      let(:result) {
        described_class.call(
          team_id: team.id,
          include_message: "true",
          message: message,
          investigation: investigation,
          current_user: user
      )
      }

      it "succeeds" do
        expect(result).to be_a_success
      end

      # rubocop:disable RSpec/ExampleLength
      it "returns the collaborator" do
        expect(result.collaborator).to have_attributes(
          team: team,
          added_by_user: user,
          investigation: investigation,
          message: message
        )
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/MultipleExpectations
      it "queues a job to notify the team", :with_test_queue_adapter do
        expect { result }.to have_enqueued_job(NotifyTeamAddedToCaseJob).with do |collaborator|
          expect(collaborator.team_id).to eql(team.id)
        end
      end
      # rubocop:enable RSpec/MultipleExpectations

      # rubocop:disable RSpec/MultipleExpectations
      it "adds an activity audit record" do
        result
        last_added_activity = investigation.activities.order(:id).first

        expect(last_added_activity).to be_a(AuditActivity::Investigation::TeamAdded)
        expect(last_added_activity.title).to eql("Testing team added to allegation")
        expect(last_added_activity.source.user_id).to eql(user.id)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
