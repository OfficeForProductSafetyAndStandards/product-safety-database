require "rails_helper"

RSpec.describe NotifyMailer, :with_stubbed_opensearch do
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

  describe "#product_export" do
    let(:user)           { create(:user) }
    let(:params)         { {} }
    let(:product_export) { ProductExport.create!(user:, params:) }

    let(:mail) { described_class.product_export(email: user.email, name: user.name, product_export:) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:product_export])
    end

    it "sets the GOV.UK Notify reference" do
      expect(mail.govuk_notify_reference).to eq("Product Export")
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, download_export_url: product_export_url(product_export))
    end
  end

  describe "#notification_export" do
    let(:user) { create(:user) }
    let(:params) { {} }
    let(:notification_export) { NotificationExport.create!(user:, params:) }

    let(:mail) { described_class.notification_export(email: user.email, name: user.name, notification_export:) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:notification_export])
    end

    it "sets the GOV.UK Notify reference" do
      expect(mail.govuk_notify_reference).to eq("Notification Export")
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, download_export_url: notification_export_url(notification_export))
    end
  end

  describe "#account_locked_inactive" do
    let(:user) { create(:user) }
    let(:token) { "abc" }
    let(:mail) { described_class.account_locked_inactive(user, token) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:account_locked_inactive])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, unlock_user_url_token: user_unlock_url(unlock_token: token))
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
          .to eq(invitation_url:, inviting_team_member_name: inviting_user.name)
      end
    end

    context "when called with a user and no inviting user" do
      let(:user)  { create(:user, :invited) }

      let(:mail)  { described_class.invitation_email(user, nil) }

      it "sets the personalisation attributes" do
        invitation_url = complete_registration_user_url(user.id, invitation: user.invitation_token)

        expect(mail.govuk_notify_personalisation)
          .to eq(invitation_url:, inviting_team_member_name: "a colleague")
      end
    end
  end

  describe "#team_added_to_notification_email" do
    subject(:mail) { described_class.team_added_to_notification_email(notification:, team:, added_by_user: user, message:, to_email: "test@example.com") }

    let(:notification) { create(:notification, creator: user) }
    let(:user) { create(:user, :activated, name: "Bob Jones") }
    let(:team) { create(:team) }

    context "with a message" do
      let(:message) { "Thanks for collaborating!" }

      it "sets the personalisation" do
        expect(mail.govuk_notify_personalisation).to eql(
          updater_name: "Bob Jones (#{user.team.name})",
          optional_message: "Message from Bob Jones (#{user.team.name}):\n\n^ Thanks for collaborating!",
          investigation_url: investigation_url(notification)
        )
      end
    end

    context "with no message" do
      let(:message) { nil }

      it "sets the personalisation" do
        expect(mail.govuk_notify_personalisation).to eql(
          updater_name: "Bob Jones (#{user.team.name})",
          optional_message: "",
          investigation_url: investigation_url(notification)
        )
      end
    end
  end

  describe "#team_removed_from_notification_email" do
    subject(:mail) do
      described_class.team_removed_from_notification_email(
        message:,
        notification:,
        team_deleted: team_to_be_deleted,
        user_who_deleted:,
        to_email: "test@example.com"
      )
    end

    let(:user_who_deleted) { create(:user, name: "Bob Jones", team: user_team) }
    let(:user_team) { create(:team, name: "User Team") }
    let(:team_to_be_deleted) { create(:team, name: "Collaborator Team") }
    let(:edit_access_collaboration) { create(:collaboration_edit_access, collaborator: team_to_be_deleted) }
    let(:notification) { edit_access_collaboration.investigation }
    let(:case_type) { "notification" }
    let(:case_title) { notification.decorate.title }

    context "with a message" do
      let(:message) { "Thanks for collaborating!" }

      it "sets the personalisation" do
        expect_personalisation_to_include_notification_attributes
        expect(mail.govuk_notify_personalisation).to include(
          updater_name: "Bob Jones (User Team)",
          optional_message: "Message from Bob Jones (User Team):\n\n^ Thanks for collaborating!",
        )
      end
    end

    context "with no message" do
      let(:message) { nil }

      it "sets the personalisation" do
        expect_personalisation_to_include_notification_attributes
        expect(mail.govuk_notify_personalisation).to include(
          updater_name: "Bob Jones (User Team)",
          optional_message: "",
        )
      end
    end
  end

  describe "#notification_updated" do
    subject(:mail) do
      described_class.notification_updated(
        notification.pretty_id,
        user.name,
        user.email,
        update_text,
        subject_text
      )
    end

    let(:notification) { create(:notification, creator: user) }
    let(:user) { create(:user, :activated, name: "Bob Jones") }
    let(:update_text) { "thing updated" }
    let(:subject_text) { "subject" }

    it "sets the personalisation" do
      expect(mail.govuk_notify_personalisation).to include(
        name: "Bob Jones",
        update_text: "thing updated",
        subject_text: "subject",
        investigation_url: investigation_url(pretty_id: notification.pretty_id)
      )
    end
  end

  describe "#notification_permission_changed_for_team" do
    subject(:mail) do
      described_class.notification_permission_changed_for_team(
        notification:,
        team:,
        user:,
        message:,
        to_email: "test@example.com",
        old_permission:,
        new_permission:
      )
    end

    let(:notification) { create(:notification, creator: user) }
    let(:case_type) { "notification" }
    let(:case_title) { notification.decorate.title }
    let(:user) { create(:user, :activated, name: "Bob Jones") }
    let(:team) { create(:team) }
    let(:old_permission) { "readonly" }
    let(:new_permission) { "edit" }

    context "with a message" do
      let(:message) { "Thanks for collaborating!" }

      it "sets the personalisation attributes for updater_name" do
        expect(mail.govuk_notify_personalisation).to include(
          updater_name: "Bob Jones (#{user.team.name})"
        )
      end

      it "sets the personalisation attributes for optional_message" do
        expect(mail.govuk_notify_personalisation).to include(
          optional_message: "Message from Bob Jones (#{user.team.name}):\n\n^ Thanks for collaborating!"
        )
      end

      it "sets the personalisation attributes for old_permission" do
        expect(mail.govuk_notify_personalisation).to include(
          old_permission: "view full notification"
        )
      end

      it "sets the personalisation attributes for new_permission" do
        expect(mail.govuk_notify_personalisation).to include(
          new_permission: "edit full notification"
        )
      end
    end

    context "with no message" do
      let(:message) { nil }

      it "sets the personalisation attributes for updater_name" do
        expect(mail.govuk_notify_personalisation).to include(
          updater_name: "Bob Jones (#{user.team.name})"
        )
      end

      it "sets the personalisation attributes for optional_message" do
        expect(mail.govuk_notify_personalisation).to include(
          optional_message: ""
        )
      end

      it "sets the personalisation attributes for old_permission" do
        expect(mail.govuk_notify_personalisation).to include(
          old_permission: "view full notification"
        )
      end

      it "sets the personalisation attributes for new_permission" do
        expect(mail.govuk_notify_personalisation).to include(
          new_permission: "edit full notification"
        )
      end
    end
  end

  describe "#expired_invitation_email" do
    let(:user) { create(:user, :invited) }
    let(:mail) { described_class.expired_invitation_email(user) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:expired_invitation])
    end
  end

  describe "#welcome" do
    let(:user) { create(:user) }
    let(:mail) { described_class.welcome(user.name, user.email) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:welcome])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name)
    end
  end

  describe "#notification_created" do
    let(:notification) { create(:notification, creator: user) }
    let(:user) { create(:user, :activated, name: "Bob Jones") }
    let(:mail) do
      described_class.notification_created(
        notification.pretty_id,
        user.name,
        user.email,
        notification.title,
        notification.class.to_s
      )
    end

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:notification_created])
    end

    it "sets the personalisation attributes for name" do
      expect(mail.govuk_notify_personalisation).to include(
        name: "Bob Jones"
      )
    end

    it "sets the personalisation attributes for case_title" do
      expect(mail.govuk_notify_personalisation).to include(
        case_title: notification.title
      )
    end

    it "sets the personalisation attributes for case_type" do
      expect(mail.govuk_notify_personalisation).to include(
        case_type: notification.class.to_s
      )
    end

    it "sets the personalisation attributes for capitalized_case_type" do
      expect(mail.govuk_notify_personalisation).to include(
        capitalized_case_type: notification.class.to_s.capitalize
      )
    end

    it "sets the personalisation attributes for case_id" do
      expect(mail.govuk_notify_personalisation).to include(
        case_id: notification.pretty_id
      )
    end

    it "sets the personalisation attributes for investigation_url" do
      expect(mail.govuk_notify_personalisation).to include(
        investigation_url: investigation_url(pretty_id: notification.pretty_id)
      )
    end
  end

  describe "#account_locked" do
    let(:user) { create(:user) }
    let(:tokens) { { reset_password_token: SecureRandom.hex, unlock_token: SecureRandom.hex } }
    let(:mail) { described_class.account_locked(user, tokens) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:account_locked])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation).to include(
        name: user.name,
        edit_user_password_url_token: edit_user_password_url(reset_password_token: tokens[:reset_password_token]),
        unlock_user_url_token: user_unlock_url(unlock_token: tokens[:unlock_token])
      )
    end
  end

  describe "#risk_validation_updated" do
    let(:user) { create(:user) }
    let(:investigation) { create(:notification, creator: user) }
    let(:mail) do
      described_class.risk_validation_updated(
        email: user.email,
        updater: user,
        investigation:,
        action: "Approved",
        name: user.name
      )
    end

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:risk_validation_updated])
    end

    it "sets the personalisation attributes for case_type" do
      expect(mail.govuk_notify_personalisation).to include(
        case_type: "notification"
      )
    end

    it "sets the personalisation attributes for case_title" do
      expect(mail.govuk_notify_personalisation).to include(
        case_title: investigation.decorate.title
      )
    end

    it "sets the personalisation attributes for case_id" do
      expect(mail.govuk_notify_personalisation).to include(
        case_id: investigation.pretty_id
      )
    end

    it "sets the personalisation attributes for updater_name" do
      expect(mail.govuk_notify_personalisation).to include(
        updater_name: user.name
      )
    end

    it "sets the personalisation attributes for updater_team_name" do
      expect(mail.govuk_notify_personalisation).to include(
        updater_team_name: user.team.name
      )
    end

    it "sets the personalisation attributes for action" do
      expect(mail.govuk_notify_personalisation).to include(
        action: "Approved"
      )
    end

    it "sets the personalisation attributes for name" do
      expect(mail.govuk_notify_personalisation).to include(
        name: user.name
      )
    end

    it "sets the personalisation attributes for investigation_url" do
      expect(mail.govuk_notify_personalisation).to include(
        investigation_url: investigation_url(pretty_id: investigation.pretty_id)
      )
    end
  end

  describe "#notification_risk_level_updated" do
    let(:user) { create(:user) }
    let(:notification) { create(:notification, creator: user) }
    let(:mail) do
      described_class.notification_risk_level_updated(
        email: user.email,
        name: user.name,
        notification:,
        update_verb: "increased",
        level: "High"
      )
    end

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:notification_risk_level_updated])
    end

    it "sets the personalisation attributes for verb_with_level" do
      expect(mail.govuk_notify_personalisation).to include(
        verb_with_level: "Increased to high"
      )
    end

    it "sets the personalisation attributes for name" do
      expect(mail.govuk_notify_personalisation).to include(
        name: user.name
      )
    end

    it "sets the personalisation attributes for case_type" do
      expect(mail.govuk_notify_personalisation).to include(
        case_type: "notification"
      )
    end

    it "sets the personalisation attributes for case_title" do
      expect(mail.govuk_notify_personalisation).to include(
        case_title: notification.decorate.title
      )
    end

    it "sets the personalisation attributes for case_id" do
      expect(mail.govuk_notify_personalisation).to include(
        case_id: notification.pretty_id
      )
    end

    it "sets the personalisation attributes for investigation_url" do
      expect(mail.govuk_notify_personalisation).to include(
        investigation_url: investigation_url(pretty_id: notification.pretty_id)
      )
    end
  end

  describe "#business_export" do
    let(:user) { create(:user) }
    let(:business_export) { create(:business_export, user:) }
    let(:mail) { described_class.business_export(email: user.email, name: user.name, business_export:) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:business_export])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, download_export_url: business_export_url(business_export))
    end
  end

  describe "#unsafe_file" do
    let(:user) { create(:user) }
    let(:mail) { described_class.unsafe_file(user:) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:unsafe_file])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name)
    end
  end

  describe "#unsafe_attachment" do
    let(:user) { create(:user) }
    let(:record_type) { "Notification" }
    let(:id) { "12345" }
    let(:mail) { described_class.unsafe_attachment(user:, record_type:, id:) }

    it "sets the recipient of the email" do
      expect(mail.to).to eq([user.email])
    end

    it "sets the template ID" do
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:unsafe_attachment])
    end

    it "sets the personalisation attributes" do
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, record_type:, id:)
    end
  end

  # TODO: remove this once all mailers are migrated to use notification param
  def expect_personalisation_to_include_case_attributes
    expect(mail.govuk_notify_personalisation).to include(
      case_type:,
      case_title:,
      case_id: investigation.pretty_id,
    )
  end

  def expect_personalisation_to_include_notification_attributes
    expect(mail.govuk_notify_personalisation).to include(
      case_type:,
      case_title:,
      case_id: notification.pretty_id,
    )
  end
end
