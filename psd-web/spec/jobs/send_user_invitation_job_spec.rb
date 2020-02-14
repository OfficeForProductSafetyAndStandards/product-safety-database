require "rails_helper"

RSpec.describe SendUserInvitationJob do
  subject(:perform) { described_class.new.perform(user_id) }

  context "with a valid user id" do
    let(:user_id) { SecureRandom.uuid }
    let(:notifications_client) { instance_double(Notifications::Client) }
    let!(:user) { create(:user, id: user_id) }

    before do
      allow(Notifications::Client).to receive(:new).and_return(notifications_client)
      allow(notifications_client).to receive(:send_email)
    end

    it "sends an invitation through Gov UK Notify" do
      expect(notifications_client).to receive(:send_email).with(
        email_address: user.email,
        template_id: "22b3799c-aa3d-43e8-899d-3f30307a488f"
      )
      perform
    end

    it "sets the user flag for having been sent the welcome email" do
      perform
      expect(user.has_been_sent_welcome_email).to be true
    end
  end

  context "with an invalid user id" do
    let(:user_id) { SecureRandom.uuid }
    let!(:user) { create(:user, id: SecureRandom.uuid) }

    it "raises an error" do
      expect { perform }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end