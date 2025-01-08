require "rails_helper"

RSpec.describe ChangeNotificationReportedReason, :with_test_queue_adapter do
  subject(:result) do
    described_class.call(notification:, user:, hazard_type: type, hazard_description: description, non_compliant_reason: c_reason, reported_reason: re_reason)
  end

  let(:type) { "liquid" }
  let(:description) { "bioluminescent green liquid" }
  let(:re_reason) { "corrosive" }
  let(:c_reason) { "health and safety risk" }
  let(:creator_team) { notification.creator_user.team }
  let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }

  let!(:notification) { create(:notification, edit_access_teams: [team_with_access]) }

  context "with no notification parameter" do
    subject(:result) do
      described_class.call(user:)
    end

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    subject(:result) do
      described_class.call(notification:)
    end

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "when it has a notification and user param but the reported reason is not ' safe and compliant '" do
    it "succeeds" do
      expect(result).to be_success
    end

    it "does not create a new activity" do
      expect { result }.not_to change(Activity, :count)
    end

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_risk_level_updated)
    end

    it "does not set a change action in the result context" do
      expect(result.change_action).to be_nil
    end

    it "type should not be empty" do
      expect(type).not_to be_nil
    end

    it "description should not be empty" do
      expect(description).not_to be_nil
    end

    it "reported reason should not be empty" do
      expect(re_reason).not_to be_nil
    end
  end

  context "when it has a notification and user param but the reported reason is 'safe_and_compliant'" do
    let(:re_reason) { "safe_and_compliant" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does create a new activity" do
      expect { result }.to change(Activity, :count).by(1)
    end

    it "does send an email" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated)
    end

    it "makes type nils" do
      expect(result.hazard_type).to be_nil
    end

    it "makes description nils" do
      expect(result.hazard_description).to be_nil
    end

    it "makes non compliant reason nils" do
      expect(result.non_compliant_reason).to be_nil
    end
  end
end
