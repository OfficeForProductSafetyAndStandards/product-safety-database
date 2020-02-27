require "rails_helper"

RSpec.describe SendResetPasswordInstructions do
  let(:token)  { SecureRandom.hex }
  let(:user)   { build(:user) }
  let(:mailer) { double(NotifyMailer, deliver_now: nil) }

  describe "#perform" do
    it "sends the email" do
      expect(NotifyMailer)
        .to receive(:reset_password_instructions)
              .with(user, token).and_return(mailer)

      described_class.perform_now(user, token)
    end
  end
end
