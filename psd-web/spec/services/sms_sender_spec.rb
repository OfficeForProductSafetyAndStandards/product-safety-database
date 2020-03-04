require "rails_helper"

<<<<<<< HEAD:psd-web/spec/services/send_sms_spec.rb
RSpec.describe SendSMS do
||||||| merged common ancestors:psd-web/spec/services/govuk_notify_spec.rb
RSpec.describe GovukNotify do
=======
RSpec.describe SMSSender do
>>>>>>> d231062006a5eeb9ac989806f3c6710e5c7572e8:psd-web/spec/services/sms_sender_spec.rb
  describe ".send_otp_code" do
    let(:mobile_number) { "123234234" }
    let(:code) { 123 }
    let(:expected_payload) do
      {
        phone_number: mobile_number,
        template_id: described_class::TEMPLATES[:send_otp_code],
        personalisation: {
          message: code,
        }
      }
    end

    it "sends the otp code" do
      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms")
        .with(body: expected_payload.to_json).and_return(body: {}.to_json)

      described_class.send_otp_code(mobile_number: mobile_number, code: code)
    end
  end
end
