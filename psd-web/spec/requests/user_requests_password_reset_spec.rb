require "rails_helper"

RSpec.describe "User requests password reset", type: :request, with_stubbed_keycloak_config: true, with_stubbed_mailer: true do
    let(:user) { create(:user, :invited, invited_at: 1.hour.ago) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  context "when the user hasn’t previously set up an account, but the invite is still valid" do
    subject(:request_password_reset) do
      post user_password_path, params: {
        user: {
          email: user.email
        }
      }
    end

    before do
      allow(NotifyMailer).to receive(:invitation_email).with(user, nil).and_return(message_delivery)
    end

    it "does not set a password reset token" do
      request_password_reset
      expect(user.reload.reset_password_token).to be_nil
    end

    it "renders the check your email page" do
      request_password_reset
      expect(response).to redirect_to(check_your_email_path)
    end

    it "re-sends the invitation email" do
      request_password_reset
      expect(message_delivery).to have_received(:deliver_later)
    end
  end


  context "when the user hasn’t previously set up an account, and the invite has expired" do
    let(:user) { create(:user, :invited, invited_at: 30.days.ago) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    subject(:request_password_reset) do
      post user_password_path, params: {
        user: {
          email: user.email
        }
      }
    end

    before do
      allow(NotifyMailer).to receive(:expired_invitation_email).with(user).and_return(message_delivery)
    end

    it "does not set a password reset token" do
      request_password_reset
      expect(user.reload.reset_password_token).to be_nil
    end

    it "renders the check your email page" do
      request_password_reset
      expect(response).to redirect_to(check_your_email_path)
    end

    it "sends an email saying their invite has expired" do
      request_password_reset
      expect(message_delivery).to have_received(:deliver_later)
    end
  end
end
