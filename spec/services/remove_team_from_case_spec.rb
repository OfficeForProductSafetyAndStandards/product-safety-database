require "rails_helper"

RSpec.describe RemoveTeamFromCase, :with_stubbed_mailer, :with_stubbed_opensearch do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation, creator: user, read_only_teams:) }

  let(:collaboration) { investigation.read_only_collaborations.last }
  let(:user) { create(:user) }
  let(:message) { "Thanks for collaborating." }

  let(:team) { create(:team, name: "Testing team") }
  let(:read_only_teams) { [team] }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no collaboration parameter" do
      let(:result) { described_class.call(user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(collaboration:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) do
        described_class.call(
          collaboration:,
          message:,
          user:
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "destroys the old collaboration", :aggregate_failures do
        result
        expect(investigation.reload.read_only_collaborations.count).to eq(0)
      end

      context "when the team has an email address" do
        it "notifies the team", :aggregate_failures do
          result
          email = delivered_emails.last
          expect(email.recipient).to eq(team.email)
          expect(email.action_name).to eq("team_deleted_from_case_email")
        end
      end

      context "when the team does not have an email address" do
        let(:team) { create(:team, team_recipient_email: nil) }
        let!(:active_team_user) { create(:user, :activated, team:, organisation: team.organisation) }
        let!(:inactive_team_user) { create(:user, :inactive, team:, organisation: team.organisation) }

        before { result }

        it "notifies the team's activated users", :aggregate_failures do
          email = delivered_emails.last
          expect(email.recipient).to eq(active_team_user.email)
          expect(email.action_name).to eq("team_deleted_from_case_email")
        end

        it "does not notify the team's inactive users" do
          expect(delivered_emails.collect(&:recipient)).not_to include(inactive_team_user.email)
        end
      end

      context "when the silent parameter is true", :with_test_queue_adapter do
        let(:result) do
          described_class.call(
            collaboration:,
            message:,
            user:,
            silent: true
          )
        end

        it "does not send any emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :team_deleted_from_case_email)
        end
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = investigation.activities.order(:id).first

        expect(last_added_activity).to be_a(AuditActivity::Investigation::TeamDeleted)
        expect(last_added_activity.added_by_user_id).to eql(user.id)
        expect(last_added_activity.metadata).to be_present

        expect(last_added_activity.decorate.title(nil)).to eql("Testing team removed from case")
      end
    end
  end
end
