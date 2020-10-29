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

    context "with required parameters that trigger a validation error" do
      let!(:test_result) { create(:test_result) }
      let(:user) { create(:user, :activated) }
      let(:new_attributes) do
        ActionController::Parameters.new({
          legislation: "",
          date: {
            year: "",
            month: "",
            day: ""
          }
        }).permit!
      end

      let(:result) { described_class.call(test_result: test_result, new_attributes: new_attributes, user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Test result edited for Allegation"
      end

      def expected_email_body(name)
        "#{name} edited a test result on the allegation."
      end

      let(:user) { create(:user, :activated) }
      let(:investigation) { create(:allegation) }
      let(:legislation) { Rails.application.config.legislation_constants["legislation"].first }
      let(:details) { "Test details" }

      # Test::Result.create triggers callbacks which generate activity and
      # emails. Create before running tests so that we can check which emails
      # are sent by the service
      let!(:test_result) do
        create(:test_result,
               investigation: investigation,
               legislation: legislation,
               details: details,
               result: :failed)
      end

      context "when there are changes to the metadata" do
        let(:updated_legislation) { Rails.application.config.legislation_constants["legislation"].last }
        let(:updated_details) { "Updated test details" }

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
          expect(activity_timeline_entry.attachment.blob).to eq(test_result.documents.first.blob)
        end

        it_behaves_like "a service which notifies the case owner"
      end

      context "when just the file attachment description is changed" do
        let(:new_attributes) do
          ActionController::Parameters.new({
            legislation: test_result.legislation,
            details: test_result.details,
            result: test_result.result,
            date: {
              year: test_result.date.year.to_s,
              month: test_result.date.month.to_s,
              day: test_result.date.day.to_s
            }
          }).permit!
        end

        let(:result) { described_class.call(test_result: test_result, new_attributes: new_attributes, user: user, new_file_description: "Updated description") }

        before do
          document = test_result.documents.first
          document.blob.update!(metadata: document.blob.metadata.merge!({ description: "Previous description" }))
        end

        it "updates the description of the attached file" do
          result
          test_result.reload
          expect(test_result.documents.first.blob.metadata[:description]).to eq "Updated description"
        end

        it "generates an activity entry with the changes" do
          result
          activity_timeline_entry = test_result.investigation.activities.where(type: AuditActivity::Test::TestResultUpdated.to_s).order(:created_at).last

          expect(activity_timeline_entry.metadata).to eq({
            "test_result_id" => test_result.id,
            "updates" => {
              "file_description" => ["Previous description", "Updated description"]
            }
          })
        end

        it_behaves_like "a service which notifies the case owner"
      end

      context "when there are no changes" do
        let(:updated_at) { 1.hour.ago }
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
          expect(test_result.reload.updated_at).to be_within(1.second).of(updated_at)
          expect(AuditActivity::Test::TestResultUpdated.where(source: test_result).size).to eq 0
        end
      end
    end
  end
end
