require "rails_helper"

RSpec.describe SendSMS, :with_stubbed_notify do
  describe ".otp_code" do
    let(:phone_number) { "123234234" }
    let(:code) { 123 }
    let(:formatted_number) { "+44123234234" }
    let(:expected_sms_params) do
      hash_including(
        phone_number: formatted_number,
        template_id: described_class::TEMPLATES[:otp_code],
        personalisation: { code: }
      )
    end

    before do
      allow(Phonelib).to receive(:parse) do |_number|
        instance_double(
          Phonelib::Phone,
          valid?: true,
          country_code: "44",
          international: formatted_number
        )
      end
    end

    it "sends the otp code" do
      described_class.otp_code(mobile_number: phone_number, code:)
      expect(notify_stub).to have_received(:send_sms).with(expected_sms_params)
    end
  end
end
