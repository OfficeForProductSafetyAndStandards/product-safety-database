require "rails_helper"

RSpec.describe SecondaryAuthentication do
  let(:attempts) { 0 }
  let(:direct_otp_sent_at) { Time.new.utc }
  let(:user) { create(:user, second_factor_attempts_count: attempts, direct_otp_sent_at: direct_otp_sent_at) }
  let(:secondary_authentication) { SecondaryAuthentication.new(user) }

  # rubocop:disable Style/MethodCalledOnDoEndBlock
  it "increase attempts when checking code" do
    expect do
      secondary_authentication.valid_otp? "123"
    end.to change { user.reload.second_factor_attempts_count }.from(0).to(1)
  end
  # rubocop:enable Style/MethodCalledOnDoEndBlock
end
