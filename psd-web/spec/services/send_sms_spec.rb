require "rails_helper"

RSpec.describe SendSMS do
  describe ".otp_code" do
    let(:phone_number) { "123234234" }
    let(:code) { 123 }
    let(:expected_payload) do
      { phone_number: phone_number, template_id: described_class::TEMPLATES[:otp_code], personalisation: { code: code } }
    end

    before do
      allow(Rails.application.config).to receive(:notify_api_key).and_return(
        "eef30646-d6cc-4708-bb7a-46d63caf752a.653d8bdf-03d1-4734-81a9-9cc687a5e1b3"
      )
    end

    it "sends the otp code" do
      notification = stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms")
                      .with(body: expected_payload.to_json).and_return(body: {}.to_json)

      described_class.otp_code(mobile_number: phone_number, code: code)

      expect(notification).to have_been_requested
    end
  end
end
