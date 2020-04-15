class SecondaryAuthentication < ApplicationRecord
  DEFAULT_OPERATION = "secondary_authentication"
  RESET_PASSWORD_OPERATION = "reset_password"
  INVITE_USER = "invite_user"
  UNLOCK_OPERATION = "unlock_operation"

  TIMEOUTS = {
    DEFAULT_OPERATION => 7 * 24 * 3600, # 7 days
    RESET_PASSWORD_OPERATION => 300, # 5 minutes
    INVITE_USER => 3600, # 1 hour
    UNLOCK_OPERATION => 300, # 5 minutes
  }

  OTP_LENGTH = 6

  attr_accessor :otp_code

  def generate_and_send_code
    generate_code
    send_two_factor_authentication_code
  end

  def generate_code
    update_attributes(
      direct_otp: random_base10(OTP_LENGTH),
      direct_otp_sent_at: Time.now.utc
    )
  end

  def send_two_factor_authentication_code
    SendTwoFactorAuthenticationJob.perform_later(User.find(self.user_id), self.direct_otp)
  end

  # raises exception
  def authenticate!
    raise "secondary authentication failed" unless otp_code == direct_otp
    update(authenticated: true, authentication_expires_at: (Time.now.utc + expiry_seconds.seconds))
  end

  def expired?
    Time.now.utc > authentication_expires_at
  end

  def expiry_seconds
    TIMEOUTS[self.operation]
  end

  private

  def random_base10(digits)
    SecureRandom.random_number(10**digits).to_s.rjust(digits, '0')
  end
end
