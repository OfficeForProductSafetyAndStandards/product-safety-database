require "rails_helper"

RSpec.describe DeleteNotification, :with_stubbed_mailer, :with_stubbed_opensearch do
  context "with no parameters" do
    subject(:delete_call) { described_class.call }

    it "returns a failure" do
      expect(delete_call).to be_failure
    end

    it "provides an error message" do
      expect(delete_call.error).to eq "No notification supplied"
    end
  end

  context "when given an notification that has products" do
    subject(:delete_call) { described_class.call(notification:, deleted_by:) }

    let(:deleted_by) { create(:user) }
    let(:notification) { create(:notification, :with_products) }

    it "returns a failure" do
      expect(delete_call).to be_failure
    end

    it "provides an error message" do
      expect(delete_call.error).to eq "Cannot delete notification with products"
    end
  end

  context "when given an notification without products" do
    subject(:delete_call) { described_class.call(notification:, deleted_by:) }

    let(:deleted_by) { create(:user) }
    let!(:notification) { create(:notification) }

    it "succeeds" do
      expect(delete_call).to be_a_success
    end

    it "sets the notification deleted_at timestamp" do
      freeze_time do
        expect {
          delete_call
          notification.reload
        }.to change(notification, :deleted_at).from(nil).to(Time.zone.now)
      end
    end

    it "changes notification deleted_by" do
      expect {
        delete_call
        notification.reload
      }.to change(notification, :deleted_by).from(nil).to(deleted_by.id)
    end

    it "does not send emails to the user or the team" do
      expect { delete_call }.not_to change(delivered_emails, :count)
    end
  end
end
