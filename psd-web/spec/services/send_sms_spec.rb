require "rails_helper"

RSpec.describe SendSMS do
  describe ".send_otp_code" do
    let(:mobile_number) { "123234234" }
    let(:code)        { 123 }

    it "sends the otp code" do
      expected_payload = {
        mobile_number: mobile_number,
        template_id: described_class::TEMPLATES[:send_otp_code],
        personalisation: {
          code: code,
        }
      }
      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms")
        .with(body: expected_payload.to_json).and_return(body: {}.to_json)

      described_class.send_otp_code(mobile_number: mobile_number, code: code)
    end
  end
end
