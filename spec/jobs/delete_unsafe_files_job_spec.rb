require "rails_helper"

# TODO: Refactor this test.
RSpec.describe DeleteUnsafeFilesJob do
  describe "#perform", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
    subject(:job) { described_class.new }

    let(:user) { create(:user) }

    context "when there are unsafe files" do
      before do
        delivered_emails.clear
      end

      context "when blob is attached" do
        context "when blob is attached to an activity" do
          let(:investigation) { create(:allegation) }
          let!(:activity) { create(:audit_activity_test_result, :with_document, investigation:) }

          before do
            delivered_emails.clear
          end
          # rubocop:disable RSpec/MultipleExpectations
          # rubocop:disable RSpec/ExampleLength

          context "when the blob has a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false, created_by: user.id }))
            end

            it "deletes document, blob and does not send email" do
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              expect(Activity.where(type: activity.type).count).to eq 1

              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))

              job.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0
              expect(Activity.where(type: activity.type).count).to eq 0

              email = delivered_emails.last
              expect(email).to eq nil
            end
          end

          context "when the blob does not have a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))
            end

            it "deletes document, blob and does not send email" do
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))

              job.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0

              email = delivered_emails.last
              expect(email).to eq nil
            end
          end
        end

        context "when blob is not attached to an activity" do
          before do
            create(:product, :with_document)
          end

          context "when the blob has a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false, created_by: user.id }))
            end

            it "deletes document, blob and does send email" do
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))

              job.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0

              email = delivered_emails.last
              expect(email.recipient).to eq user.email
              expect(email.action_name).to eq "unsafe_attachment"
            end
          end

          context "when the blob does not have a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))
            end

            it "deletes document, blob and does not send email" do
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update!(metadata: blob.metadata.merge({ safe: false }))

              job.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0

              email = delivered_emails.last
              expect(email).to eq nil
            end
          end
        end
      end

      context "when blob is not attached" do
        let!(:product) { create(:product, :with_document) }

        before do
          blob = ActiveStorage::Blob.first
          blob.update!(metadata: blob.metadata.merge({ safe: false }))
        end

        it "deletes blob and does not send email" do
          product.documents.detach
          expect(ActiveStorage::Attachment.count).to eq 0
          expect(ActiveStorage::Blob.count).to eq 1

          job.perform

          expect(ActiveStorage::Blob.count).to eq 0

          email = delivered_emails.last
          expect(email).to eq nil
        end
      end
    end

    context "when there are no unsafe files" do
      before do
        create(:product, :with_document)
      end

      context "when the blob has a created_by field in the metadata" do
        it "does not delete any blobs, attachments or send any emails" do
          expect(ActiveStorage::Attachment.count).to eq 1
          expect(ActiveStorage::Blob.count).to eq 1

          job.perform

          expect(ActiveStorage::Attachment.count).to eq 1
          expect(ActiveStorage::Blob.count).to eq 1
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
