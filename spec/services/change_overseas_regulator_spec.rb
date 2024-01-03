require "rails_helper"

RSpec.describe ChangeOverseasRegulator, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let(:investigation) { create(:allegation, is_from_overseas_regulator: true, overseas_regulator_country: "country:AM") }
  let(:user) { create(:user, name: "User One") }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameters" do
      let(:result) do
        described_class.call(
          user:,
          investigation:,
          is_from_overseas_regulator: true,
          overseas_regulator_country:
        )
      end

      let(:activity_entry) { investigation.activities.where(type: AuditActivity::Investigation::ChangeOverseasRegulator.to_s).order(:created_at).last }

      context "when no changes have been made" do
        let(:overseas_regulator_country) { "country:AM" }

        it "does not generate an activity entry" do
          result

          expect(investigation.activities.where(type: AuditActivity::Investigation::ChangeOverseasRegulator.to_s)).to eq []
        end

        it "does not send any notification updated emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_updated)
        end
      end

      context "when changes have been made" do
        let(:overseas_regulator_country) { "country:US" }

        it "updates the investigation", :aggregate_failures do
          result

          expect(investigation.overseas_regulator_country).to eq("country:US")
        end

        it "creates an activity entry" do
          result

          expect(activity_entry.metadata).to eql({
            "updates" => {
              "overseas_regulator_country" => ["country:AM", "country:US"]
            }
          })
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited overseas regulator on the notification.",
            "Overseas regulator edited for notification"
          )
        end
      end
    end
  end
end
