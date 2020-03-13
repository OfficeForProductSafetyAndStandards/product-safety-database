require "rails_helper"

RSpec.describe SendSMS do
  describe ".otp_code" do
    let(:phone_number) { "123234234" }
    let(:code) { 123 }
    let(:expected_payload) do
      { phone_number: phone_number, template_id: described_class::TEMPLATES[:otp_code], personalisation: { code: code } }
    end

    it "sends the otp code" do
      notification = stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms")
                      .with(body: expected_payload.to_json).and_return(body: {}.to_json)

      described_class.otp_code(mobile_number: phone_number, code: code)

      expect(notification).to have_been_requested
    end
  end
end
