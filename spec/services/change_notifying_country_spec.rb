require "rails_helper"

RSpec.describe ChangeNotifyingCountry, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let(:investigation) { create(:allegation) }
  let(:user) { create(:user, name: "User One") }
  let(:notifying_country_uk) { "country:GB-ENG" }
  let(:notifying_country_overseas) { "country:FR" }
  let(:overseas_or_uk) { "uk" }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user:, overseas_or_uk:, notifying_country_uk:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation:, overseas_or_uk:, notifying_country_uk:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no overseas_or_uk parameter" do
      let(:result) { described_class.call(user:, investigation:, notifying_country_uk:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with an overseas_or_uk parameter" do
      context "when it is set to uk with no notifying_country_uk parameter" do
        let(:result) { described_class.call(user:, investigation:, overseas_or_uk:, notifying_country_overseas:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "when it is set to overseas with no notifying_country_overseas parameter" do
        let(:result) { described_class.call(user:, investigation:, overseas_or_uk: "overseas", notifying_country_uk:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end
    end

    context "with the required parameters" do
      let(:result) do
        described_class.call(
          user:,
          investigation:,
          notifying_country_uk:,
          notifying_country_overseas:,
          overseas_or_uk:
        )
      end

      let(:activity_entry) { investigation.activities.where(type: AuditActivity::Investigation::ChangeNotifyingCountry.to_s).order(:created_at).last }

      context "when no changes have been made" do
        let(:notifying_country_uk) { "country:GB-ENG" }
        let(:overseas_or_uk) { "uk" }

        before do
          investigation.update_column(:notifying_country, notifying_country_uk)
        end

        it "does not generate an activity entry" do
          result

          expect(investigation.activities.where(type: AuditActivity::Investigation::ChangeNotifyingCountry.to_s)).to eq []
        end

        it "does not send any case updated emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end

      context "when changes have been made" do
        let(:notifying_country_uk) { "country:GB-NIR" }
        let(:overseas_or_uk) { "uk" }

        it "updates the risk assessment", :aggregate_failures do
          result

          expect(investigation.notifying_country).to eq("country:GB-NIR")
        end

        it "creates an activity entry" do
          result

          expect(activity_entry.metadata).to eql({
            "updates" => {
              "notifying_country" => ["country:GB-ENG", "country:GB-NIR"]
            }
          })
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited notifying country on the case.",
            "Notifying country edited for Case"
          )
        end
      end
    end
  end
end
