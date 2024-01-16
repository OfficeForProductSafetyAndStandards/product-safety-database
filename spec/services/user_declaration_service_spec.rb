describe UserDeclarationService do
  describe ".accept_declaration" do
    let(:user) { create(:user, has_accepted_declaration: false, account_activated: false) }
    let(:mailer) { instance_double("ActionMailer::MessageDelivery", deliver_later: true) }

    before do
      allow(NotifyMailer).to receive(:welcome).with(user.name, user.email).and_return(mailer)
      described_class.accept_declaration(user)
    end

    it "sets the user accepted declaration flag" do
      expect(user).to be_has_accepted_declaration
    end

    it "sets the user account activated flag" do
      expect(user).to be_account_activated
    end

    context "when the user has already been sent a welcome email" do
      let(:user) { create(:user, has_been_sent_welcome_email: true) }

      it "does not send a welcome email" do
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    context "when the user has not already been sent a welcome email" do
      let(:user) { create(:user, has_been_sent_welcome_email: false) }

      it "sends a welcome email to the user" do
        expect(mailer).to have_received(:deliver_later).once
      end

      it "sets the has been sent welcome email flag" do
        expect(user).to be_has_been_sent_welcome_email
      end
    end
  end
end
