module DeviseHooks
  extend ActiveSupport::Concern

  def send_two_factor_authentication_code(code)
    SendTwoFactorAuthenticationJob.perform_later(self, code)
  end

private

  def send_reset_password_instructions_notification(token)
    SendResetPasswordInstructions.perform_later(self, token)
  end
end
