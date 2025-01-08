require "rails_helper"

RSpec.describe UpdateTestResult, :with_stubbed_antivirus, :with_stubbed_mailer, :with_test_queue_adapter do
  subject(:result) { described_class.call(params) }

  let(:user)                                     { create(:user, :activated) }
  let(:investigation)                            { create(:allegation) }
  let(:product)                                  { create(:product) }
  let(:investigation_product)                    { create(:investigation_product) }
  let(:test_result)                              { create(:test_result, investigation:, investigation_product:) }

  let(:new_details)                              { Faker::Hipster.sentence }
  let(:new_legislation) do
    (Rails.application.config.legislation_constants["legislation"] - [test_result.legislation]).sample
  end
  let(:new_date)                                 { test_result.date - 2.days }
  let(:new_standards_product_was_tested_against) { Faker::Hipster.words }
  let(:new_document)                             { ActiveStorage::Blob.create_and_upload!(io: File.open(file_fixture("new_test_result.txt")), filename: "new_test_result.txt") }
  let(:new_result)                               { (Test::Result.results.keys - [test_result.result]).sample }
  let(:new_attributes) do
    {
      details: new_details,
      legislation: new_legislation,
      date: new_date,
      result: new_result,
      investigation_product_id: investigation_product.id,
      standards_product_was_tested_against: new_standards_product_was_tested_against,
      document: new_document
    }
  end
  let(:test_result_form) { TestResultForm.from(test_result).tap { |form| form.assign_attributes(new_attributes) } }
  let(:changes)          { test_result_form.changes }
  let(:params) do
    test_result_form
      .serializable_hash
      .merge(
        test_result:,
        user:,
        investigation:,
        changes:
      )
  end

  describe ".call" do
    context "with a missing parameters" do
      context "when missing the user" do
        let(:user) { nil }

        it "returns a failure indicating a user was not supplied", :aggregate_failures do
          expect(result).to be_failure
          expect(result.error).to eq("No user supplied")
        end
      end

      context "when missing the investigation" do
        let(:params) { new_attributes.merge(test_result:, user:) }

        it "returns a failure indicating an investigation was not supplied", :aggregate_failures do
          expect(result).to be_failure
          expect(result.error).to eq("No investigation supplied")
        end
      end

      context "when missing the test result" do
        let(:params) { new_attributes.merge(user:, investigation:, changes:) }

        it "returns a failure indicating a test result was not supplied", :aggregate_failures do
          expect(result).to be_failure
          expect(result.error).to eq("No test result supplied")
        end
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Test result edited for notification"
      end

      def expected_email_body(name)
        "#{name} edited a test result on the notification."
      end
      let!(:expected_changes_metadata) do
        {
          "test_result_id" => test_result.id,
          "updates" => {
            "date" => [test_result.date.to_s, new_date.to_s],
            "details" => [test_result.details, new_details],
            "result" => [test_result.result, new_result],
            "legislation" => [test_result.legislation, new_legislation],
            "standards_product_was_tested_against" => [
              test_result.standards_product_was_tested_against, new_standards_product_was_tested_against
            ]
          }
        }
      end
      let(:activity_timeline_entry) { test_result.investigation.activities.where(type: AuditActivity::Test::TestResultUpdated.to_s).order(:created_at).last }

      context "when there are changes to the metadata" do
        it "updates the model and creates an activity log entry", :aggregate_failures do
          result
          test_result.reload
          expect(test_result).to have_attributes(new_attributes.except(:document, :existing_document_file_id))
          expect(activity_timeline_entry.metadata).to eq(expected_changes_metadata)
        end

        it_behaves_like "a service which notifies the investigation owner"

        it "retains the original file" do
          expect { result }.not_to have_enqueued_job(ActiveStorage::PurgeJob)
        end
      end

      context "when there are no changes" do
        let(:updated_at) { 1.hour.ago }
        let(:new_attributes) do
          {
            legislation: test_result.legislation,
            details: test_result.details,
            result: test_result.result,
            date: {
              year: test_result.date.year.to_s,
              month: test_result.date.month.to_s,
              day: test_result.date.day.to_s
            }
          }
        end

        let(:result) { described_class.call(test_result:, new_attributes:, user:) }

        before do
          # Have to do this after setup as attaching the document also updates the
          # updated_at timestamp
          test_result.update_column(:updated_at, updated_at)
        end

        it "does not make any database changes", :aggregate_failures do
          result
          expect(test_result.reload.updated_at).to be_within(1.second).of(updated_at)
          expect(AuditActivity::Test::TestResultUpdated.where(added_by_user: user).size).to eq 0
        end
      end
    end
  end
end
