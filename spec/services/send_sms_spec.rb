require "rails_helper"

RSpec.describe SendSMS, :with_stubbed_notify do
  describe ".otp_code" do
    subject(:send_otp) { described_class.otp_code(mobile_number: phone_number, code:) }

    let(:code) { "123456" }
    let(:template_id) { described_class::TEMPLATES[:otp_code] }
    let(:phone_number) { "07123456789" }
    let(:notify_client) { instance_double(Notifications::Client) }

    before do
      allow(Notifications::Client).to receive(:new)
        .with(Rails.configuration.notify_api_key)
        .and_return(notify_client)
      allow(notify_client).to receive(:send_sms)
    end

    shared_examples "sends SMS with formatted number" do |input_number, expected_number|
      let(:phone_number) { input_number }
      let(:expected_payload) do
        {
          phone_number: expected_number,
          template_id:,
          personalisation: { code: }
        }
      end

      it "sends the SMS with correctly formatted number" do
        send_otp
        expect(notify_client).to have_received(:send_sms).with(expected_payload)
      end
    end

    context "with valid UK numbers" do
      it_behaves_like "sends SMS with formatted number", "07123 456 789", "+447123456789"
      it_behaves_like "sends SMS with formatted number", "7123456789", "+447123456789"
      it_behaves_like "sends SMS with formatted number", "+447123 456789", "+447123456789"
    end

    context "with invalid phone numbers" do
      invalid_numbers = [
        "12345",              # Too short
        "071234567890123",    # Too long
        "+33123456789",       # Non-UK number
        "abcdefghijk",        # Non-numeric
        "",                   # Empty string
        nil                   # Nil value
      ]

      invalid_numbers.each do |invalid_number|
        context "when phone number is #{invalid_number.inspect}" do
          let(:phone_number) { invalid_number }

          it "does not send SMS" do
            send_otp
            expect(notify_client).not_to have_received(:send_sms)
          end
        end
      end
    end

    context "when initializing the client" do
      it "uses the configured API key" do
        send_otp
        expect(Notifications::Client).to have_received(:new).with(Rails.configuration.notify_api_key)
      end
    end
  end

  describe "#normalize_uk_number" do
    subject(:service) { described_class.new }

    context "with private methods" do
      test_cases = {
        "07123456789" => "+447123456789",       # Starting with 0
        "7123456789" => "+447123456789",        # No leading 0
        "+447123456789" => "+447123456789",     # Already formatted
        "07123 456 789" => "+447123456789",     # Spaced numbers
        "7123 456 789" => "+447123456789",
        "+447123 456 789" => "+447123456789",
        "07123 456789" => "+447123456789",
        "040-071234133" => "+4440071234133", # Hyphenated
        "01234-567-980" => "+441234567980"
      }

      test_cases.each do |input, expected|
        it "correctly formats #{input} to #{expected}" do
          expect(service.send(:normalize_uk_number, input)).to eq(expected)
        end
      end
    end
  end

  describe "#valid_phone_number?" do
    subject(:service) { described_class.new }

    context "with private methods" do
      valid_numbers = [
        "+447123456789",
        "+447890123456",
      ]

      valid_numbers.each do |number|
        it "returns true for valid UK number: #{number}" do
          expect(service.send(:valid_phone_number?, number)).to be true
        end
      end
    end
  end
end
