require "rails_helper"

RSpec.describe SendUserInvitationJob do
  describe "#perform" do
    subject(:job) { described_class.new }

    context "with a valid user id" do
      let(:user_id) { SecureRandom.uuid }
      let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
      let!(:user) { create(:user, id: user_id, invitation_token: SecureRandom.hex(10), invited_at:, has_been_sent_welcome_email: false) }
      let(:invited_at) { 1.hour.ago }

      context "with a user inviting id" do
        before do
          allow(NotifyMailer).to receive(:invitation_email).with(user, user_inviting).and_return(message_delivery_instance)
          job.perform(user_id, user_inviting_id)
        end

        let(:user_inviting) { create(:user) }
        let(:user_inviting_id) { user_inviting.id }

        it "sends an email via the NotifyMailer" do
          expect(message_delivery_instance).to have_received(:deliver_now)
        end

        it "sets the user flag for having been sent the welcome email" do
          expect(user.reload.has_been_sent_welcome_email).to be true
        end
      end

      context "with no user inviting id" do
        let(:user_inviting) { nil }
        let(:user_inviting_id) { nil }

        context "with user whose invitation is still valid" do
          let(:invited_at) { 2.hours.ago }

          before do
            allow(NotifyMailer).to receive(:invitation_email).with(user, user_inviting).and_return(message_delivery_instance)
            job.perform(user_id, user_inviting_id)
          end

          it "re-sends the invitation email via the NotifyMailer" do
            expect(message_delivery_instance).to have_received(:deliver_now)
          end
        end

        context "with user whose invitation has expired" do
          let(:invited_at) { 30.days.ago }

          before do
            allow(NotifyMailer).to receive(:expired_invitation_email).with(user).and_return(message_delivery_instance)
            job.perform(user_id, user_inviting_id)
          end

          it "sends an email about the expired notification via the NotifyMailer" do
            expect(message_delivery_instance).to have_received(:deliver_now)
          end
        end

        context "with user who has not been invited before" do
          before do
            allow(NotifyMailer).to receive(:invitation_email).with(user, user_inviting).and_return(message_delivery_instance)
            job.perform(user_id, user_inviting_id)
          end

          it "sends an email via the NotifyMailer" do
            expect(message_delivery_instance).to have_received(:deliver_now)
          end

          it "sets the user flag for having been sent the welcome email" do
            expect(user.reload.has_been_sent_welcome_email).to be true
          end
        end
      end
    end

    context "with an invalid user id" do
      let(:user_id) { SecureRandom.uuid }
      let!(:user_inviting) { create(:user) }

      it "raises an error" do
        expect { job.perform(user_id, user_inviting.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
