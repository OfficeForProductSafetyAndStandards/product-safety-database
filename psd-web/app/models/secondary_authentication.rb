class SecondaryAuthentication < ApplicationRecord
  DEFAULT_OPERATION = "secondary_authentication".freeze
  RESET_PASSWORD_OPERATION = "reset_password".freeze
  INVITE_USER = "invite_user".freeze
  UNLOCK_OPERATION = "unlock_operation".freeze

  TIMEOUTS = {
    DEFAULT_OPERATION => 7 * 24 * 3600, # 7 days
    RESET_PASSWORD_OPERATION => 300, # 5 minutes
    INVITE_USER => 3600, # 1 hour
    UNLOCK_OPERATION => 300, # 5 minutes
  }.freeze

  OTP_LENGTH = 6
  MAX_ATTEMPTS = Rails.configuration.two_factor_attempts
  OTP_EXPIRY_SECONDS = 300

  belongs_to :user

  def generate_and_send_code
    generate_code
    send_two_factor_authentication_code
  end

  def otp_needs_refreshing?
    otp_locked? || otp_expired?
  end

  def otp_expired?
    self.direct_otp_sent_at && (self.direct_otp_sent_at + OTP_EXPIRY_SECONDS) < Time.now.utc
  end

  def otp_locked?
    self.attempts > MAX_ATTEMPTS
  end

  def valid_otp?(otp)
    self.increment!(:attempts)
    otp == self.direct_otp
  end

  def generate_code
    update(
      attempts: 0,
      direct_otp: random_base10(OTP_LENGTH),
      direct_otp_sent_at: Time.now.utc
    )
  end

  def send_two_factor_authentication_code
    SendTwoFactorAuthenticationJob.perform_later(User.find(self.user_id), self.direct_otp)
  end

  def authenticate!
    update(authenticated: true, authentication_expires_at: (Time.now.utc + expiry_seconds.seconds))
    try_to_verify_user_mobile_number
  end

  def expired?
    authentication_expires_at && Time.now.utc > authentication_expires_at
  end

  def expiry_seconds
    TIMEOUTS[self.operation]
  end

  def try_to_verify_user_mobile_number
    user.update(mobile_number_verified: true) unless user.mobile_number_verified
  end

private

  def random_base10(digits)
    SecureRandom.random_number(10**digits).to_s.rjust(digits, "0")
  end
end
