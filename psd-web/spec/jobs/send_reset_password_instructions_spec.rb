require "rails_helper"

RSpec.describe SendResetPasswordInstructions do
  let(:token)  { SecureRandom.hex }
  let(:user)   { build(:user) }

  let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

  describe "#perform" do
    before do
      allow(NotifyMailer).to receive(:reset_password_instructions).and_return(message_delivery_instance)
    end

    it "sends the email" do
      described_class.perform_now(user, token)
      expect(message_delivery_instance).to have_received(:deliver_now)
    end
  end
end
