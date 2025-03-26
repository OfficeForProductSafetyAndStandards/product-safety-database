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

  describe ".hard_delete_old_drafts!" do
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
      old_draft
      recent_draft
      old_submitted
    end

    it "permanently deletes old draft notifications" do
      expect {
        described_class.hard_delete_old_drafts!
      }.to change(described_class, :count).by(-1)

      expect { old_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "preserves recent draft notifications" do
      expect {
        described_class.hard_delete_old_drafts!
      }.not_to(change { recent_draft.reload.deleted_at })
    end

    it "preserves old submitted notifications" do
      expect {
        described_class.hard_delete_old_drafts!
      }.not_to(change { old_submitted.reload.deleted_at })
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
