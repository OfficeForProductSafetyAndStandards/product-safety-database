require "rails_helper"

RSpec.describe ChangeCaseRiskLevel, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  describe ".call" do
    subject(:result) do
      described_class.call(investigation: investigation,
                           user: user,
                           risk_level: new_level,
                           custom_risk_level: new_custom)
    end

    let(:previous_level) { nil }
    let(:new_level) { nil }
    let(:previous_custom) { nil }
    let(:new_custom) { nil }
    let(:creator_team) { investigation.creator_user.team }
    let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
    let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }
    let(:investigation) { create(:enquiry, risk_level: previous_level, custom_risk_level: previous_custom) }

    before do
      AddTeamToCase.call!(user: user,
                          investigation: investigation,
                          team: team_with_access)
    end

    context "with no investigation parameter" do
      subject(:result) do
        described_class.call(user: user, risk_level: new_level, custom_risk_level: new_custom)
      end

      it "fails" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      subject(:result) do
        described_class.call(investigation: investigation, risk_level: new_level, custom_risk_level: new_custom)
      end

      it "fails" do
        expect(result).to be_failure
      end
    end

    context "when the previous risk level and the new risk level are the same" do
      let(:previous_level) { "high" }
      let(:new_level) { "high" }

      it "succeeds" do
        expect(result).to be_success
      end

      it "does not create a new activity" do
        expect { result }.not_to change(Activity, :count)
      end

      it "does not send an email" do
        expect { result }.not_to have_enqueued_mail(NotifyMailer, :case_risk_level_updated)
      end

      it "does not set a change action in the result context" do
        expect(result.change_action).to be_nil
      end

      it "does not set the updated risk level in the result context" do
        expect(result.updated_risk_level).to be_nil
      end
    end

    context "when the previous risk level was not set" do
      let(:previous_level) { nil }

      context "with a different new risk level" do
        let(:new_level) { "high" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "sets the risk level for the investigation" do
          expect { result }.to change(investigation, :risk_level).from(previous_level).to(new_level)
        end

        it "creates a new activity for the risk level being set", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::RiskLevelUpdated)
          expect(activity.metadata).to include(
            "updates" => { "risk_level" => [previous_level, new_level] },
            "update_verb" => "set"
          )
        end

        it "sends an email for the risk level being set" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: creator_team.team_recipient_email,
            name: creator_team.name,
            investigation: investigation,
            update_verb: "set",
            level: "High risk"
          )
        end

        it "sets a change action in the result context" do
          expect(result.change_action).to eq :set
        end

        it "sets the updated risk level in the result context" do
          expect(result.updated_risk_level).to eq "High risk"
        end
      end

      context "with empty new risk level" do
        let(:new_level) { "" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "does not create a new activity" do
          expect { result }.not_to change(Activity, :count)
        end

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :case_risk_level_updated)
        end

        it "does not set a change action in the result context" do
          expect(result.change_action).to be_nil
        end

        it "does not set the updated risk level in the result context" do
          expect(result.updated_risk_level).to be_nil
        end
      end
    end

    context "when the custom risk level was previously set" do
      let(:previous_level) { "other" }
      let(:previous_custom) { "Custom level" }

      context "with a different custom risk level" do
        let(:new_level) { "other" }
        let(:new_custom) { "New custom level" }

        it "succeeds" do
          expect(result).to be_success
        end

        it "changes the custom risk level for the investigation" do
          expect { result }.to change(investigation, :custom_risk_level)
                           .from(previous_custom)
                           .to(new_custom)
        end

        it "creates a new activity for the change", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::RiskLevelUpdated)
          expect(activity.metadata).to include(
            "updates" => { "custom_risk_level" => [previous_custom, new_custom] },
            "update_verb" => "changed"
          )
        end

        it "sends an email for the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: creator_team.team_recipient_email,
            name: creator_team.name,
            investigation: investigation,
            update_verb: "changed",
            level: new_custom
          )
        end

        it "sets a change action in the result context" do
          expect(result.change_action).to eq :changed
        end

        it "sets the updated risk level in the result context" do
          expect(result.updated_risk_level).to eq new_custom
        end
      end

      context "with empty new risk level and custom risk level" do
        let(:new_custom) { nil }
        let(:new_level) { nil }

        it "succeeds" do
          expect(result).to be_success
        end

        it "removes the custom level from the investigation" do
          expect { result }.to change(investigation, :custom_risk_level).from(previous_custom).to(new_custom)
        end

        it "creates a new activity for the removal", :aggregate_failures do
          expect { result }.to change(Activity, :count).by(1)
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Investigation::RiskLevelUpdated)
          expect(activity.metadata).to include(
            "updates" => { "custom_risk_level" => [previous_custom, new_custom], "risk_level" => [previous_level, new_level] },
            "update_verb" => "removed"
          )
        end

        it "sets a change action in the result context" do
          expect(result.change_action).to eq :removed
        end

        it "sets the updated risk level as not set the result context" do
          expect(result.updated_risk_level).to eq "Not set"
        end

        it "sends an email for the removal" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :case_risk_level_updated).with(
            email: creator_team.team_recipient_email,
            name: creator_team.name,
            investigation: investigation,
            update_verb: "removed",
            level: "Not set"
          )
        end
      end
    end
  end
end
