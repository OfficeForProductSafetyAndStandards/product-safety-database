require "rails_helper"

RSpec.describe AddTeamToCase, :with_stubbed_mailer, :with_stubbed_opensearch do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation) }

  let(:user) { create(:user) }
  let(:team) { create(:team, name: "Testing team") }
  let(:message) { "Thanks for collaborating." }
  let(:collaboration_class) { Collaboration::Access::Edit }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(team:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(team:, investigation:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no team parameter" do
      let(:result) { described_class.call(investigation:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) do
        described_class.call(
          team:,
          message:,
          investigation:,
          collaboration_class:,
          user:
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "returns the collaborator" do
        expect(result.collaboration).to have_attributes(
          collaborator: team,
          added_by_user: user,
          investigation:,
          message:
        )
      end

      context "when adding with edit permissions" do
        let(:collaboration_class) { Collaboration::Access::Edit }

        it "creates an edit collaboration" do
          expect(result.collaboration).to be_a(Collaboration::Access::Edit)
        end
      end

      context "when adding with view only permissions" do
        let(:collaboration_class) { Collaboration::Access::ReadOnly }

        it "creates a read only collaboration" do
          expect(result.collaboration).to be_a(Collaboration::Access::ReadOnly)
        end
      end

      context "when the team has an email address" do
        it "notifies the team", :aggregate_failures do
          result
          email = delivered_emails.last
          expect(email.recipient).to eq(team.email)
          expect(email.action_name).to eq("team_added_to_case_email")
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
          expect(email.action_name).to eq("team_added_to_case_email")
        end

        it "does not notify the team's inactive users" do
          expect(delivered_emails.collect(&:recipient)).not_to include(inactive_team_user.email)
        end
      end

      context "when the silent parameter is true", :with_test_queue_adapter do
        let(:result) do
          described_class.call(
            team:,
            message:,
            investigation:,
            collaboration_class:,
            user:,
            silent: true
          )
        end

        it "does not send any emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :team_added_to_case_email)
        end
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = investigation.activities.order(:id).first

        expect(last_added_activity).to be_a(AuditActivity::Investigation::TeamAdded)
        expect(last_added_activity.added_by_user_id).to eql(user.id)
        expect(last_added_activity.metadata).to be_present

        expect(last_added_activity.decorate.title(nil)).to eql("Testing team added to notification")
      end

      context "when the team has already been added to the case" do
        before { result }

        it "does not create a new collaboration record" do
          expect { result }.not_to change(investigation.collaborations, :count)
        end

        it "does not send an email" do
          expect { result }.not_to change(delivered_emails, :count)
        end

        it "does not create an audit activity record" do
          expect { result }.not_to change(investigation.activities, :count)
        end
      end
    end
  end
end
