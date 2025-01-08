require "rails_helper"

RSpec.describe "User requests password reset", :with_stubbed_mailer, type: :request do
  context "when the user hasn’t previously set up an account" do
    subject(:request_password_reset) do
      post user_password_path,
           params: {
             user: {
               email: user.email
             }
           }
    end

    let(:user) { create(:user, :invited, invited_at: 1.hour.ago) }

    it "does not set a password reset token" do
      request_password_reset
      expect(user.reload.reset_password_token).to be_nil
    end

    it "renders the check your email page" do
      request_password_reset
      expect(response).to redirect_to(check_your_email_path)
    end

    it "queues the resend invitation job", :aggregate_failures, :with_test_queue_adapter do
      expect { request_password_reset }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
        expect(recipient_id).to eq user.id
        expect(inviting_user_id).to be_nil
      end
    end
  end
end
