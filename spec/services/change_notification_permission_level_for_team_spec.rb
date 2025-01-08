require "rails_helper"

RSpec.describe ChangeNotificationPermissionLevelForTeam, :with_stubbed_mailer, :with_stubbed_opensearch do
  let!(:notification) { create(:notification, creator: user, read_only_teams:) }

  let(:user) { create(:user) }
  let(:message) { "Thanks for collaborating." }
  let(:new_collaboration_class) { Collaboration::Access::Edit }

  let(:team) { create(:team, name: "Testing team") }
  let(:read_only_teams) { [team] }
  let(:existing_collaboration) { notification.read_only_collaborations.last }

  context "with no parameters" do
    let(:result) { described_class.call }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no existing_collaboration parameter" do
    let(:result) { described_class.call(new_collaboration_class:, user:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    let(:result) { described_class.call(existing_collaboration:, new_collaboration_class:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no new_collaboration_class parameter" do
    let(:result) { described_class.call(existing_collaboration:, user:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with required parameters" do
    let(:result) do
      described_class.call(
        existing_collaboration:,
        message:,
        new_collaboration_class:,
        user:
      )
    end

    it "succeeds" do
      expect(result).to be_a_success
    end

    it "destroys the old collaboration", :aggregate_failures do
      result
      expect(notification.reload.read_only_collaborations.count).to eq(0)
    end

    it "returns the new collaboration" do
      expect(result.collaboration).to have_attributes(
        collaborator: team,
        added_by_user: user,
        investigation: notification,
        message:
      )
    end

    context "when adding with edit permissions" do
      let(:new_collaboration_class) { Collaboration::Access::Edit }

      it "creates an edit collaboration" do
        expect(result.collaboration).to be_a(Collaboration::Access::Edit)
      end
    end

    context "when adding with view only permissions" do
      let(:new_collaboration_class) { Collaboration::Access::ReadOnly }

      it "creates a read only collaboration" do
        expect(result.collaboration).to be_a(Collaboration::Access::ReadOnly)
      end
    end

    context "when the team has an email address" do
      it "notifies the team", :aggregate_failures do
        result
        email = delivered_emails.last
        expect(email.recipient).to eq(team.email)
        expect(email.action_name).to eq("notification_permission_changed_for_team")
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
        expect(email.action_name).to eq("notification_permission_changed_for_team")
      end

      it "does not notify the team's inactive users" do
        expect(delivered_emails.collect(&:recipient)).not_to include(inactive_team_user.email)
      end
    end

    it "adds an audit activity record", :aggregate_failures do
      result
      last_added_activity = notification.activities.order(:id).first

      expect(last_added_activity).to be_a(AuditActivity::Investigation::TeamPermissionChanged)
      expect(last_added_activity.added_by_user_id).to eql(user.id)
      expect(last_added_activity.metadata).to be_present

      expect(last_added_activity.decorate.title(nil)).to eql("Testing team's notification permission level changed")
    end
  end
end
