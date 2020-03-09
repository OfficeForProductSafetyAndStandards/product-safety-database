require "rails_helper"

RSpec.describe SendUserInvitationJob do
  describe "#perform" do
    subject(:job) { described_class.new }

    context "with a valid user id and user inviting id" do
      let(:user_id) { SecureRandom.uuid }
      let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
      let!(:user) { create(:user, id: user_id, invitation_token: SecureRandom.hex(10), invited_at: nil, has_been_sent_welcome_email: false) }
      let!(:user_inviting) { create(:user) }

      before do
        allow(NotifyMailer).to receive(:invitation_email).and_return(message_delivery_instance)
      end

      it "sends an email via the NotifyMailer" do
        allow(NotifyMailer).to receive(:invitation_email).with(user, user_inviting).and_return(message_delivery_instance)
        job.perform(user_id, user_inviting.id)
        expect(message_delivery_instance).to have_received(:deliver_now)
      end

      it "adds the time that the user was invited" do
        job.perform(user_id, user_inviting.id)
        expect(user.reload.invited_at).to be_within(1.second).of(Time.zone.now)
      end

      it "sets the user flag for having been sent the welcome email" do
        job.perform(user_id, user_inviting.id)
        expect(user.reload.has_been_sent_welcome_email).to be true
      end
    end

    context "with an invalid user id" do
      let(:user_id) { SecureRandom.uuid }
      let!(:user_inviting) { create(:user) }

      it "raises an error" do
        expect { job.perform(user_id, user_inviting.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with no user inviting id and user whose invitation is still valid" do
      let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
      let(:invited_at) { 2.hours.ago }
      let!(:user) { create(:user, :invited, invited_at: invited_at) }

      before do
        allow(NotifyMailer).to receive(:invitation_email).and_return(message_delivery_instance)
      end

      it "re-sends the invitation email via the NotifyMailer" do
        allow(NotifyMailer).to receive(:invitation_email).with(user).and_return(message_delivery_instance)
        job.perform(user.id)
        expect(message_delivery_instance).to have_received(:deliver_now)
      end

      it "does not change the the time that the user was invited at" do
        job.perform(user.id)
        expect(user.reload.invited_at).to be_within(1.second).of(invited_at)
      end
    end

    context "with no user inviting id and user whose invitation is has expired" do
      let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }
      let(:invited_at) { 30.days.ago }
      let!(:user) { create(:user, :invited, invited_at: invited_at) }

      before do
        allow(NotifyMailer).to receive(:expired_invitation_email).and_return(message_delivery_instance)
      end

      it "sends an email about the expired notification via the NotifyMailer" do
        allow(NotifyMailer).to receive(:expired_invitation_email).with(user).and_return(message_delivery_instance)
        job.perform(user.id)
        expect(message_delivery_instance).to have_received(:deliver_now)
      end

      it "does not change the the time that the user was invited at" do
        job.perform(user.id)
        expect(user.reload.invited_at).to be_within(1.second).of(invited_at)
      end
    end
  end
end
