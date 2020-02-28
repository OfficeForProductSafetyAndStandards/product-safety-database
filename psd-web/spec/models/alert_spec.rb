require "rails_helper"

RSpec.describe Alert do
  describe "#send_alert_email" do
    subject(:alert) { described_class.new(summary: "test", description: "test") }
    before { allow(SendAlertJob).to receive(:perform_later) }

    it "sends an email to activated users only" do
      activated_user = create(:user, :activated, email: "activated@example.com")
      create(:user, :inactive, email: "unactivated@example.com")

      alert.send_alert_email

      expect(SendAlertJob).to have_received(:perform_later).with([activated_user.email], subject_text: "test", body_text: "test")
    end
  end
end
