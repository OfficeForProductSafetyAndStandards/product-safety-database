require "rails_helper"

RSpec.describe SendResetPasswordInstructions do
  let(:token) { SecureRandom.hex }
  let(:user) { build(:user) }

  describe "#perform" do
    it "sends the email" do
      expect(NotifyMailer).to receive(:reset_password_instruction).with(user, token)

      SendResetPasswordInstructions
    end
  end
end
