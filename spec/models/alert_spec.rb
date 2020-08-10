require "rails_helper"

RSpec.describe Alert do
  describe "#send_alert_email" do
    subject(:alert) { described_class.new(summary: "test", description: "test") }

    let(:activated_user) { create(:user, :activated, email: "activated@example.com") }

    before { create(:user, :inactive, email: "unactivated@example.com") }

    it "sends an email to activated users only", :with_test_queue_adapter, :aggregate_failures do
      expect { alert.send_alert_email }.to have_enqueued_job(SendAlertJob).at(:no_wait).on_queue("psd").with do |recipients, subject_text, body_text|
        expect(recipients).to eq [activated_user.email]
        expect(subject_text).to eq "test"
        expect(body_text).to eq "test"
      end
    end
  end
end
