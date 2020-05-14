require "rails_helper"

RSpec.describe NotifyMailer, :with_stubbed_elasticsearch do
  describe "#reset_password_instruction" do
    let(:user)  { build(:user) }
    let(:token) { SecureRandom.hex }
    let(:mail)  { described_class.reset_password_instructions(user, token) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:reset_password_instruction])
    end

    it "sets the GOV.UK Notify reference" do
      expect(mail.govuk_notify_reference).to eq("Password reset")
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, edit_user_password_url_token: edit_user_password_url(reset_password_token: token))
    end
  end

  describe "#invitation_email" do
    context "when called with a user and an inviting user" do
      let(:user)  { create(:user, :invited) }
      let(:inviting_user) { build(:user) }

      let(:mail) { described_class.invitation_email(user, inviting_user) }

      it "sets the recipient of the email" do
        expect(mail.to).to eq([user.email])
      end

      it "sets the template ID" do
        expect(mail.govuk_notify_template).to eq("7b80a680-f8b3-4032-982d-2a3a662b611a")
      end

      it "sets the personalisation attributes" do
        invitation_url = complete_registration_user_url(user.id, invitation: user.invitation_token)

        expect(mail.govuk_notify_personalisation)
          .to eq(invitation_url: invitation_url, inviting_team_member_name: inviting_user.name)
      end
    end

    context "when called with a user and no inviting user" do
      let(:user)  { create(:user, :invited) }

      let(:mail)  { described_class.invitation_email(user, nil) }

      it "sets the personalisation attributes" do
        invitation_url = complete_registration_user_url(user.id, invitation: user.invitation_token)

        expect(mail.govuk_notify_personalisation)
          .to eq(invitation_url: invitation_url, inviting_team_member_name: "a colleague")
      end
    end
  end

  describe "#team_added_to_case_email" do
    let(:added_by_user) { create(:user, name: "Bob Jones", team: user_team) }
    let(:collaborator) { create(:collaborator, message: message, added_by_user: added_by_user, team: collaborator_team) }
    let(:user_team) { create(:team, name: "User Team") }
    let(:collaborator_team) { create(:team, name: "Collaborator Team") }

    subject(:mail) { described_class.team_added_to_case_email(collaborator, to_email: "test@example.com") }

    context "with a message" do
      let(:message) { "Thanks for collaborating!" }

      context "when the user is on another team" do
        it "sets the personalisation" do
          expect(mail.govuk_notify_personalisation).to eql(
            updater_name: "Bob Jones (User Team)",
            optional_message: "Message from Bob Jones (User Team):\n\n^ Thanks for collaborating!",
            investigation_url: investigation_url(collaborator.investigation)
          )
        end
      end

      context "when the user is on the same team" do
        let(:collaborator_team) { user_team }

        it "sets the personalisation" do
          expect(mail.govuk_notify_personalisation).to eql(
            updater_name: "Bob Jones",
            optional_message: "Message from Bob Jones:\n\n^ Thanks for collaborating!",
            investigation_url: investigation_url(collaborator.investigation)
          )
        end
      end
    end

    context "with no message" do
      let(:message) { nil }

      it "sets the personalisation" do
        expect(mail.govuk_notify_personalisation).to eql(
          updater_name: "Bob Jones (User Team)",
          optional_message: "",
          investigation_url: investigation_url(collaborator.investigation)
        )
      end
    end
  end
end
