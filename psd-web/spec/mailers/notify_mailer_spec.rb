require "rails_helper"

RSpec.describe NotifyMailer do
  describe ".reset_password_instruction" do
    let(:user)  { build(:user) }
    let(:token) { SecureRandom.hex }
    let(:mail)  { described_class.reset_password_instruction(user, token) }

    it "configures and send the email with the correct personalisation" do
      expect(mail.to).to eq([user.email])
      expect(mail.govuk_notify_template).to eq(described_class::TEMPLATES[:reset_password_instruction])
      expect(mail.govuk_notify_reference).to eq("Password reset")
      expect(mail.govuk_notify_personalisation)
        .to eq(name: user.name, reset_url: edit_user_password_url(reset_password_token: token))
    end
  end
end
