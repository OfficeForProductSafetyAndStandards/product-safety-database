require "rails_helper"

RSpec.describe SecondaryAuthentication do
  let(:attempts) { 0 }
  let(:direct_otp_sent_at) { Time.new.utc }
  let(:secondary_authentication) { create(:secondary_authentication, attempts: attempts, direct_otp_sent_at: direct_otp_sent_at) }

  it "increase attempts when checking code" do
    expect do
      secondary_authentication.valid_otp? "123"
    end.to change { secondary_authentication.reload.attempts }.from(0).to(1)
  end
end
