require "rails_helper"
require "sidekiq/testing"

RSpec.describe DeleteUnsafeFilesJob, type: :job do
  describe "#perform", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
    subject(:perform_job) { job.perform }

    let(:job) { described_class.new }
    let(:user) { create(:user) }

    RSpec.shared_context "with unsafe blob" do
      before do
        delivered_emails.clear
        blob.update!(metadata: blob.metadata.merge({ safe: false }.merge(created_by_metadata)))
      end
    end

    RSpec.shared_examples "deletes unsafe content" do
      it "deletes the attachment" do
        expect { perform_job }.to change(ActiveStorage::Attachment, :count).by(-1)
      end

      it "deletes the blob" do
        expect { perform_job }.to change(ActiveStorage::Blob, :count).by(-1)
      end
    end

    RSpec.shared_examples "keeps files intact" do
      it "maintains existing attachments" do
        expect { perform_job }.not_to change(ActiveStorage::Attachment, :count)
      end

      it "maintains existing blobs" do
        expect { perform_job }.not_to change(ActiveStorage::Blob, :count)
      end

      it "sends no emails" do
        perform_job
        expect(delivered_emails).to be_empty
      end
    end

    context "when blob is attached to an activity" do
      let(:investigation) { create(:allegation) }
      let!(:activity) { create(:audit_activity_test_result, :with_document, investigation:) }
      let(:blob) { ActiveStorage::Blob.first }

      context "when blob has created_by metadata" do
        let(:created_by_metadata) { { created_by: user.id } }

        include_context "with unsafe blob"

        include_examples "deletes unsafe content"

        it "deletes the activity" do
          expect { perform_job }.to change(Activity, :count).by(-1)
          expect { activity.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not send email" do
          perform_job
          expect(delivered_emails.last).to be_nil
        end
      end

      context "when blob has no created_by metadata" do
        let(:created_by_metadata) { {} }

        include_context "with unsafe blob"
        include_examples "deletes unsafe content"
      end
    end

    context "with unsafe unattached blob" do
      let!(:product) { create(:product, :with_document) }

      before do
        delivered_emails.clear
        blob = ActiveStorage::Blob.first
        blob.update!(metadata: { safe: false })
        product.documents.detach
      end

      it "deletes the blob" do
        expect { perform_job }.to change(ActiveStorage::Blob, :count).by(-1)
      end

      it "sends no email" do
        perform_job
        expect(delivered_emails).to be_empty
      end
    end

    context "with safe attached blob" do
      before do
        create(:product, :with_document)
        delivered_emails.clear
      end

      include_examples "keeps files intact"
    end

    context "with safe unattached blob" do
      before do
        product = create(:product, :with_document)
        product.documents.detach
        delivered_emails.clear
      end

      include_examples "keeps files intact"
    end
  end

  describe "#delete_attachments", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
    subject(:delete_attachments) { job.send(:delete_attachments, attachments, user) }

    let(:job) { described_class.new }
    let(:user) { create(:user) }
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
    let(:notify_mailer) { class_spy(NotifyMailer, unsafe_attachment: mailer_double) }

    before do
      allow(NotifyMailer).to receive(:unsafe_attachment).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_later)
    end

    context "when attachment belongs to an ImageUpload" do
      let!(:image_upload) { create(:image_upload) }
      let!(:attachments) { ActiveStorage::Attachment.where(record: image_upload) }

      it "deletes the image upload" do
        expect { delete_attachments }.to change(ImageUpload, :count).by(-1)
      end

      it "deletes the attachment" do
        expect { delete_attachments }.to change(ActiveStorage::Attachment, :count).by(-1)
        expect(ActiveStorage::Attachment.exists?(attachments.first.id)).to be false
      end

      it "sends email notification" do
        delete_attachments
        expect(NotifyMailer).to have_received(:unsafe_attachment)
          .with(user: user, record_type: "ImageUpload", id: image_upload.id)
      end
    end

    context "when user is nil" do
      let(:user) { nil }
      let!(:image_upload) { create(:image_upload) }
      let!(:attachments) { ActiveStorage::Attachment.where(record: image_upload) }

      it "deletes the attachment" do
        expect { delete_attachments }.to change(ActiveStorage::Attachment, :count).by(-1)
        expect(ActiveStorage::Attachment.exists?(attachments.first.id)).to be false
      end

      it "does not send email notification" do
        expect(NotifyMailer).not_to have_received(:unsafe_attachment)
        delete_attachments
      end
    end
  end

  # test sidekiq with the Job
  describe "#perform_later" do
    before do
      ActiveJob::Base.queue_adapter = :test
      Sidekiq::Testing.fake!
    end

    it "adds job to the queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class)
    end

    it "adds job to specific queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job.on_queue(ENV["SIDEKIQ_QUEUE"] || "psd")
    end

    it "changes queue size" do
      expect {
        described_class.perform_later
      }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end
  end
end
