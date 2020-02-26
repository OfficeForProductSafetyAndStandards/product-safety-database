class SendTwoFactorAuthenticationJob < ApplicationJob
  def perform(user, code)
    GovukNotify.send_otp_code(mobile_number: user.mobile_number, code: code)
  end
end
