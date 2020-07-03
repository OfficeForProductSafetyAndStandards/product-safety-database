require "rails_helper"

RSpec.describe ChangeCaseRiskLevel, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  describe ".call" do
    subject(:result) do
      described_class.call(investigation: investigation, user: user, risk_level: new_risk_level)
    end

    let(:previous_risk_level) { nil }
    let(:new_risk_level) { nil }
    let(:team_with_access) { create(:team, name: "Team with access") }
    let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }
    let(:investigation) { create(:enquiry, risk_level: previous_risk_level) }

    before do
      AddTeamToAnInvestigation.call!(current_user: user, investigation: investigation, collaborator_id: team_with_access.id, include_message: false)
    end

    context "with no investigation parameter" do
      subject(:result) { described_class.call(user: user, risk_level: new_risk_level) }

      it "fails" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      subject(:result) { described_class.call(investigation: investigation, risk_level: new_risk_level) }

      it "fails" do
        expect(result).to be_failure
      end
    end

    context "when the previous risk level and the new risk level are the same" do
      let(:previous_risk_level) { "Low Risk" }
      let(:new_risk_level) { previous_risk_level }

      it "succeeds" do
        expect(result).to be_success
      end

      it "does not create a new activity" do
        expect { result }.not_to change(Activity, :count)
      end

      it "does not send an email" do
        expect { result }.not_to have_enqueued_mail(NotifyMailer, :case_risk_level_updated)
      end
    end

    context "when the previous risk level was not set" do
      let(:previous_risk_level) { nil }

      context "with a different new risk level" do
        let(:new_risk_level) { "Low Risk" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "sets the risk level for the investigation" do
          expect { result }.to change(investigation, :risk_level).from(previous_risk_level).to(new_risk_level)
        end

        it "creates a new activity for the risk level being set", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::UpdateRiskLevel)
          expect(activity.metadata).to include("risk_level" => new_risk_level, "action" => "set")
        end

        it "sends an email for the risk level being set" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: investigation.creator_user.email,
            name: investigation.creator_user.name,
            investigation: investigation,
            action: "set",
            level: new_risk_level
          )
        end
      end

      context "with empty new risk level" do
        let(:new_risk_level) { "" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "does not create a new activity" do
          expect { result }.not_to change(Activity, :count)
        end

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :case_risk_level_updated)
        end
      end
    end

    context "when the previous risk level was previously set" do
      let(:previous_risk_level) { "Low Risk" }

      context "with a different new risk level" do
        let(:new_risk_level) { "Medium Risk" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "changes the risk level for the investigation" do
          expect { result }.to change(investigation, :risk_level).from(previous_risk_level).to(new_risk_level)
        end

        it "creates a new activity for the change", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::UpdateRiskLevel)
          expect(activity.metadata).to include("risk_level" => new_risk_level, "action" => "changed")
        end

        it "sends an email for the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: investigation.creator_user.email,
            name: investigation.creator_user.name,
            investigation: investigation,
            action: "changed",
            level: new_risk_level
          )
        end
      end

      context "with empty new risk level" do
        let(:new_risk_level) { nil }

        it "succeeds" do
          expect(result).to be_success
        end

        it "removes the risk level from the investigation" do
          expect { result }.to change(investigation, :risk_level).from(previous_risk_level).to(new_risk_level)
        end

        it "creates a new activity for the removal", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::UpdateRiskLevel)
          expect(activity.metadata).to include("risk_level" => nil, "action" => "removed")
        end

        it "sends an email for the removal" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: investigation.creator_user.email,
            name: investigation.creator_user.name,
            investigation: investigation,
            action: "removed",
            level: nil
          )
        end
      end
    end
  end
end
