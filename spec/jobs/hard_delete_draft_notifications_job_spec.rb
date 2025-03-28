require "rails_helper"

RSpec.describe HardDeleteDraftNotificationsJob, type: :job do
  describe "#perform" do
    subject(:job) { described_class.new }

    context "when the feature flag is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(:submit_notification_reminder).and_return(false)
        allow(Investigation::Notification).to receive(:hard_delete_old_drafts!)
      end

      it "does not call hard_delete_old_drafts!" do
        job.perform
        expect(Investigation::Notification).not_to have_received(:hard_delete_old_drafts!)
      end
    end

    context "when the feature flag is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(:submit_notification_reminder).and_return(true)
        allow(Investigation::Notification).to receive(:hard_delete_old_drafts!)
      end

      it "calls hard_delete_old_drafts! on Investigation::Notification" do
        job.perform
        expect(Investigation::Notification).to have_received(:hard_delete_old_drafts!)
      end
    end
  end
end
