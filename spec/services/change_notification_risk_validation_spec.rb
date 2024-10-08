require "rails_helper"

RSpec.describe ChangeNotificationRiskValidation, :with_test_queue_adapter do
  subject(:result) do
    described_class.call(notification:, user:, risk_validated_at: risk_validate, risk_validated_by: risk_validatetwo, is_risk_validated: risk_validated)
  end

  let(:risk_validate) { nil }
  let(:risk_validatetwo) { nil }
  let(:risk_validated) { false }
  let(:creator_team) { notification.creator_user.team }
  let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }

  # Create the notification before test run to ensure we only check activity generated by the test
  let!(:notification) { create(:notification, risk_validated_at: risk_validate, risk_validated_by: risk_validatetwo, edit_access_teams: [team_with_access]) }

  context "with no notification parameter" do
    subject(:result) do
      described_class.call(user:, risk_validated_at: risk_validate, risk_validated_by: risk_validatetwo)
    end

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    subject(:result) do
      described_class.call(notification:, risk_validated_at: risk_validate, risk_validated_by: risk_validatetwo)
    end

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "when risk_validated_at and risk_validated_by are left unchanged" do
    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :risk_validation_updated)
    end

    it "does not set a change action in the result context" do
      expect(result.change_action).to eq("has had validation removed")
    end

    it "does not create a new activity" do
      expect { result }.not_to change(Activity, :count)
    end
  end

  context "when both the risk validated at and risk validated by are filled" do
    let(:risk_validate) { "20/07/2021" }
    let(:risk_validatetwo) { "Test User" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does create a new activity" do
      expect { result }.to change(Activity, :count)
    end

    it "does not send an email" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :risk_validation_updated)
    end
  end

  context "when the risk is validated" do
    let(:risk_validated) { true }

    it "does set a change action in the result context" do
      expect(result.change_action).to eq("has been validated")
    end
  end
end
