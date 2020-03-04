class SendTwoFactorAuthenticationJob < ApplicationJob
  def perform(user, code)
    SendSMS.send_otp_code(mobile_number: user.mobile_number, code: code)
  end
end
