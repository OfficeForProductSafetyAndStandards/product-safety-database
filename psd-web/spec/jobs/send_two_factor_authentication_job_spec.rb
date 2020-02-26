require "rails_helper"

RSpec.describe SendTwoFactorAuthenticationJob do
  let(:user) { create(:user) }
  let(:code) { 123 }

  it "send the otp code" do
    allow(GovukNotify).to receive(:send_otp_code)

    described_class.perform_now(user, code)

    expect(GovukNotify)
      .to have_received(:send_otp_code)
      .with(mobile_number: user.mobile_number, code: code)
  end
end
