require "rails_helper"

RSpec.describe SendTwoFactorAuthenticationJob do
  let(:user) { create(:user) }
  let(:code) { 123 }

  it "send the otp code" do
    expect(SendSMS)
      .to receive(:send_otp_code)
      .with(mobile_number: user.mobile_number, code: code)

    described_class.perform_now(user, code)
  end
end
