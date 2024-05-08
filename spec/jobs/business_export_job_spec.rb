require "rails_helper"

RSpec.describe BusinessExportJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:user) { create(:user) }
    let(:business_export) { create(:business_export, user:) }
    let(:mailer) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(business_export).to receive(:export!).and_call_original
      allow(NotifyMailer).to receive(:business_export).and_return(mailer)
      allow(mailer).to receive(:deliver_later)
    end

    it "calls export! on the business_export object" do
      described_class.perform_now(business_export)
      expect(business_export).to have_received(:export!).once
    end

    it "sends an email with the correct parameters" do
      described_class.perform_now(business_export)

      expect(NotifyMailer).to have_received(:business_export).with(
        email: user.email,
        name: user.name,
        business_export:
      )
      expect(mailer).to have_received(:deliver_later)
    end

    context "when an exception occurs" do
      let(:mock_error) { StandardError.new("random error") }

      before do
        allow(business_export).to receive(:export!).and_raise(mock_error)
        allow(Sentry).to receive(:capture_exception)
      end

      it "captures the exception with Sentry and re-raises it" do
        expect { described_class.perform_now(business_export) }.to raise_error(StandardError, "random error")
        expect(Sentry).to have_received(:capture_exception).with(mock_error)
      end
    end
  end
end
