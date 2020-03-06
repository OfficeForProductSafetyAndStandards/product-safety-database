require "rails_helper"

RSpec.describe NotifyMailer do
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
end
