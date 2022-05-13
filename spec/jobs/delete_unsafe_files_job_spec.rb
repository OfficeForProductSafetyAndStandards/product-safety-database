require "rails_helper"

RSpec.describe DeleteUnsafeFilesJob do
  describe "#perform", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
    subject(:job) { described_class.new }
    let(:user) { create(:user) }

    context "when there are unsafe files" do
      before(:each) do
        delivered_emails.clear
      end
      context "when blob is attached" do
        context "when blob is attached to an activity" do
          let(:investigation) { create(:allegation) }
          let!(:activity) { create(:audit_activity_test_result, :with_document, investigation: investigation) }

          before do
            delivered_emails.clear
          end

          context "when the blob has a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false, created_by: user.id}))
            end

            it "deletes document, blob and does not send email" do
              # delivered_emails.clear
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false}))

              DeleteUnsafeFilesJob.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0

              email = delivered_emails.last
              expect(email).to eq nil
            end
          end

          context "when the blob does not have a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false}))
            end

            it "deletes document, blob and does not send email" do
              # delivered_emails.clear
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false}))

              DeleteUnsafeFilesJob.perform

              expect(ActiveStorage::Attachment.count).to eq 0
              expect(ActiveStorage::Blob.count).to eq 0

              email = delivered_emails.last
              expect(email).to eq nil
            end
          end
        end

        context "when blob is not attached to an activity" do
          let!(:product) { create(:product, :with_document) }

          context "when the blob has a created_by field in the metadata" do
            before do
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false, created_by: user.id}))
            end

            it "deletes document, blob and does not send email" do
              # delivered_emails.clear
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false}))

              DeleteUnsafeFilesJob.perform

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
              blob.update(metadata: blob.metadata.merge({safe: false}))
            end

            it "deletes document, blob and does not send email" do
              # delivered_emails.clear
              expect(ActiveStorage::Attachment.count).to eq 1
              expect(ActiveStorage::Blob.count).to eq 1
              blob = ActiveStorage::Blob.first
              blob.update(metadata: blob.metadata.merge({safe: false}))

              DeleteUnsafeFilesJob.perform

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
          blob.update(metadata: blob.metadata.merge({safe: false}))
        end

        it "deletes blob and does not send email" do
          # delivered_emails.clear
          product.documents.detach
          expect(ActiveStorage::Attachment.count).to eq 0
          expect(ActiveStorage::Blob.count).to eq 1

          DeleteUnsafeFilesJob.perform

          expect(ActiveStorage::Blob.count).to eq 0

          email = delivered_emails.last
          expect(email).to eq nil
        end
      end
    end
  end
end
