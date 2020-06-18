require "rails_helper"

RSpec.describe UpdateTestResult, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_test_queue_adapter do
  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with a missing parameters" do
      let(:test_result) { build(:test_result) }
      let(:result) { described_class.call(test_result: test_result) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:editing_user_team) { create(:team, name: "Test team 2") }
      let(:user) { create(:user, :activated, name: "User 2", team: editing_user_team) }
      let(:product) { create(:product) }
      let(:owner_team) { create(:team,
        name: "Test team 1",
        team_recipient_email: "test-team@example.com")
      }
      let(:investigation) { create(:allegation, owner: owner_team)}

      context "when there are changes" do
        let(:legislation) { Rails.application.config.legislation_constants["legislation"].first }
        let(:updated_legislation) { Rails.application.config.legislation_constants["legislation"].last }

        let(:details) { "Test details" }
        let(:updated_details) { "Updated test details" }

        let(:test_result) do
          create(:test_result,
                 investigation: investigation,
                 legislation: legislation,
                 details: details,
                 product: product,
                 result: :failed)
        end
        let(:new_attributes) do
          ActionController::Parameters.new({
            legislation: updated_legislation,
            details: updated_details,
            result: test_result.result,
            date: {
              year: test_result.date.year.to_s,
              month: test_result.date.month.to_s,
              day: test_result.date.day.to_s
            }
          }).permit!
        end
        let(:result) { described_class.call(test_result: test_result, new_attributes: new_attributes, user: user) }

        let(:expected_metadata) do
          {
            "test_result_id" => test_result.id,
            "updates" => {
              "legislation" => [legislation, updated_legislation],
              "details" => [details, updated_details]
            }
          }
        end

        it "updates the model and creates an activity log entry", :aggregate_failures do
          result
          expect(test_result.reload.details).to eq updated_details
          expect(test_result.reload.legislation).to eq updated_legislation

          activity_timeline_entry = test_result.investigation.activities.where(type: AuditActivity::Test::TestResultUpdated.to_s).order(:created_at).last

          expect(activity_timeline_entry.metadata).to eq(expected_metadata)
        end

        it "sends a notification email to the case owner" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            test_result.investigation.pretty_id,
            "Test team 1",
            "test-team@example.com",
            "User 2 (Test team 2) edited a test result on the allegation.",
            "Test result edited for Allegation"
          )
        end
      end

      context "when there are no changes" do
        let(:legislation) { Rails.application.config.legislation_constants["legislation"].first }
        let(:updated_at) { 1.hour.ago }
        let(:test_result) do
          create(:test_result,
                 investigation: create(:allegation),
                 legislation: legislation,
                 details: "Test details",
                 product: product,
                 result: :failed)
        end
        let(:new_attributes) do
          ActionController::Parameters.new({
            legislation: legislation,
            details: test_result.details,
            result: test_result.result,
            date: {
              year: test_result.date.year.to_s,
              month: test_result.date.month.to_s,
              day: test_result.date.day.to_s
            }
          }).permit!
        end
        let(:result) { described_class.call(test_result: test_result, new_attributes: new_attributes, user: user) }

        before do
          # Have to do this after setup as attaching the document also updates the
          # updated_at timestamp
          test_result.update_column(:updated_at, updated_at)
        end

        it "does not make any database changes", :aggregate_failures do
          result
          expect(test_result.reload.updated_at).to eq(updated_at)
          expect(AuditActivity::Test::TestResultUpdated.where(source: test_result).size).to eq 0
        end
      end
    end
  end
end
