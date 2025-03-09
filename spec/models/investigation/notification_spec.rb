require "rails_helper"

RSpec.describe Investigation::Notification, :with_stubbed_antivirus, :with_stubbed_mailer do
  subject(:notification) { build(:notification) }

  describe "#case_type" do
    it "returns 'notification'" do
      expect(notification.case_type).to eq("notification")
    end
  end

  describe "#valid?" do
    subject(:notification) { build(:notification, date_received:).build_owner_collaborations_from(create(:user)) }

    context "with valid date_received" do
      let(:date_received) { 1.day.ago }

      it { is_expected.to be_valid }
    end

    context "with empty date_received" do
      let(:date_received) { nil }

      it { is_expected.to be_valid }
    end
  end

  describe "#valid_api_dataset?" do
    context "with a valid API dataset" do
      subject(:notification) { build(:notification) }

      it { is_expected.to be_valid_api_dataset }
    end

    context "with an invalid API dataset" do
      subject(:notification) { build(:notification, user_title: nil) }

      it { is_expected.not_to be_valid_api_dataset }
    end
  end

  describe ".soft_delete_old_drafts!" do
    let(:user) { create(:user, :activated, :opss_user) }
    let(:old_draft) { create_notification(state: "draft", updated_at: 91.days.ago, pretty_id: "2024-0001") }
    let(:recent_draft) { create_notification(state: "draft", updated_at: 89.days.ago, pretty_id: "2024-0002") }
    let(:old_submitted) { create_notification(state: "submitted", updated_at: 91.days.ago, pretty_id: "2024-0003") }

    def create_notification(state:, updated_at:, pretty_id:)
      notification = build(:notification, state:, updated_at:, pretty_id:)
      notification.build_owner_collaborations_from(user)
      notification.save!(validate: false)
      notification
    end

    before do
      allow(CreateNotification).to receive(:call).and_return(OpenStruct.new(success?: true))
      allow(old_draft).to receive(:reindex)
      old_draft
    end

    shared_examples "soft deletes old draft notifications" do
      it "sets deleted_at" do
        described_class.soft_delete_old_drafts!
        expect(old_draft.reload.deleted_at).to be_present
      end

      it "sets deleted_by to 'System'" do
        described_class.soft_delete_old_drafts!
        expect(old_draft.reload.deleted_by).to eq("System")
      end
    end

    shared_examples "preserves notifications" do |notification_type|
      it "does not delete #{notification_type}" do
        described_class.soft_delete_old_drafts!
        notification = send(notification_type)
        expect(notification.reload.deleted_at).to be_nil
      end
    end

    shared_examples "creates audit activity" do
      it "creates an audit activity" do
        expect { described_class.soft_delete_old_drafts! }
          .to change(AuditActivity::Investigation::AutomaticallyClosedCase, :count).by(1)
      end

      it "links the audit activity to the notification" do
        described_class.soft_delete_old_drafts!
        activity = AuditActivity::Investigation::AutomaticallyClosedCase.last
        expect(activity.investigation).to eq(old_draft)
      end

      it "includes the notification ID in the audit activity metadata" do
        described_class.soft_delete_old_drafts!
        activity = AuditActivity::Investigation::AutomaticallyClosedCase.last
        expect(activity.metadata["notification_id"]).to eq(old_draft.id)
      end

      it "includes the closed_at timestamp in the audit activity metadata" do
        freeze_time do
          described_class.soft_delete_old_drafts!
          activity = AuditActivity::Investigation::AutomaticallyClosedCase.last
          expect(Time.zone.parse(activity.metadata["closed_at"].to_s)).to eq(Time.current)
        end
      end
    end

    include_examples "soft deletes old draft notifications"
    include_examples "preserves notifications", :recent_draft
    include_examples "preserves notifications", :old_submitted
    include_examples "creates audit activity"

    it "calls reindex on the notification" do
      relation = instance_double(ActiveRecord::Relation)
      allow(described_class).to receive(:old_drafts).and_return(relation)
      allow(relation).to receive(:find_each).and_yield(old_draft)
      allow(old_draft).to receive(:reindex)
      described_class.soft_delete_old_drafts!
      expect(old_draft).to have_received(:reindex).once
    end

    it "logs the number of processed notifications" do
      allow(Rails.logger).to receive(:info)
      described_class.soft_delete_old_drafts!
      expect(Rails.logger).to have_received(:info).with("Starting to soft delete old draft notifications")
      expect(Rails.logger).to have_received(:info).with("Completed soft deleting old draft notifications. Processed: 1")
    end

    context "when an error occurs" do
      let(:error_message) { "Test error" }
      let(:relation) { instance_double(ActiveRecord::Relation) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
        allow(described_class).to receive(:old_drafts).and_return(relation)
        allow(relation).to receive(:find_each).and_yield(old_draft)
        allow(old_draft).to receive(:mark_as_deleted!).and_raise(StandardError.new(error_message))
      end

      it "logs the error and continues processing" do
        described_class.soft_delete_old_drafts!
        expect(Rails.logger).to have_received(:error).with("Failed to soft delete notification #{old_draft.id}: #{error_message}")
      end
    end
  end

  describe "#virus_free_images" do
    let(:notification) { create(:notification) }

    context "when all images are virus-free" do
      let!(:safe_image) { create(:image_upload, :with_antivirus_safe_image_upload, upload_model: notification) }
      let!(:safe_image_two) { create(:image_upload, :with_antivirus_safe_image_upload, upload_model: notification) }

      before do
        allow(notification).to receive(:image_uploads).and_return([safe_image, safe_image_two])
      end

      it "returns all images" do
        expect(notification.virus_free_images).to contain_exactly(safe_image, safe_image_two)
      end
    end

    context "when some images are infected" do
      let!(:safe_image) { create(:image_upload, :with_antivirus_safe_image_upload, upload_model: notification) }
      let(:unsafe_image) { create(:image_upload, :with_virus_image_upload, upload_model: notification) }

      before do
        allow(notification).to receive(:image_uploads).and_return([safe_image, unsafe_image])
      end

      it "returns only virus-free images" do
        expect(notification.virus_free_images).to contain_exactly(safe_image)
      end
    end

    context "when image_uploads is empty" do
      before do
        allow(notification).to receive(:image_uploads).and_return([])
      end

      it "returns empty array" do
        expect(notification.virus_free_images).to be_empty
      end
    end
  end
end
