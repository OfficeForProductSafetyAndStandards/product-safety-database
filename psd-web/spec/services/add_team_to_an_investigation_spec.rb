require "rails_helper"

RSpec.describe AddTeamToAnInvestigation, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  describe ".call" do
    context "with required parameters" do
      # Create the case before running tests so that we can check which emails are sent by the service
      let!(:investigation) { create(:allegation) }

      let(:user) { create(:user) }
      let(:team) { create(:team, name: "Testing team") }
      let(:message) { "Thanks for collaborating." }

      let(:result) do
        described_class.call(
          collaborator_id: team.id,
          include_message: "true",
          message: message,
          investigation: investigation,
          current_user: user
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "returns the collaborator" do
        expect(result.edit_access_collaboration).to have_attributes(
          collaborator: team,
          added_by_user: user,
          investigation: investigation,
          message: message
        )
      end

      it "queues a job to notify the team", :with_test_queue_adapter do
        aggregate_failures do
          expect { result }.to have_enqueued_job(NotifyTeamAddedToCaseJob).with do |collaborator|
            expect(collaborator.team_id).to eql(team.id)
          end
        end
      end

      it "does not queue the generic case updated mailer job", :with_test_queue_adapter do
        expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
      end

      # rubocop:disable RSpec/ExampleLength
      it "adds an activity audit record" do
        result
        last_added_activity = investigation.activities.order(:id).first

        aggregate_failures do
          expect(last_added_activity).to be_a(AuditActivity::Investigation::TeamAdded)
          expect(last_added_activity.title).to eql("Testing team added to allegation")
          expect(last_added_activity.source.user_id).to eql(user.id)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
