require "rails_helper"

RSpec.describe "User requests password reset", type: :request, with_stubbed_mailer: true do
  context "when the user hasn’t previously set up an account" do
    subject(:request_password_reset) do
      post user_password_path, params: {
        user: {
          email: user.email
        }
      }
    end

    let(:user) { create(:user, :invited, invited_at: 1.hour.ago) }

    before do
      allow(SendUserInvitationJob).to receive(:perform_later).with(user.id, nil)
    end

    it "does not set a password reset token" do
      request_password_reset
      expect(user.reload.reset_password_token).to be_nil
    end

    it "renders the check your email page" do
      request_password_reset
      expect(response).to redirect_to(check_your_email_path)
    end

    it "queues the resend invitation job" do
      request_password_reset
      expect(SendUserInvitationJob).to have_received(:perform_later).with(user.id, nil)
    end
  end
end
