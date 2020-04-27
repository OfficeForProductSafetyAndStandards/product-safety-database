class SecondaryAuthentication
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

  OTP_LENGTH = 5
  MAX_ATTEMPTS = Rails.configuration.two_factor_attempts
  MAX_ATTEMPTS_COOLDOWN = 3600 # 1 hour
  OTP_EXPIRY_SECONDS = 300

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def generate_and_send_code(operation)
    generate_code(operation)
    send_secondary_authentication_code
  end

  def otp_expired?
    user.direct_otp_sent_at && (user.direct_otp_sent_at + OTP_EXPIRY_SECONDS) < Time.now.utc
  end

  def otp_locked?
    user.second_factor_attempts_locked_at.present? && (user.second_factor_attempts_locked_at + MAX_ATTEMPTS_COOLDOWN.seconds) > Time.now.utc
  end

  def valid_otp?(otp)
    try_to_unlock_secondary_authentication

    user.increment!(:second_factor_attempts_count) unless otp_locked?

    if user.second_factor_attempts_count > MAX_ATTEMPTS
      user.update(second_factor_attempts_locked_at: Time.now.utc, second_factor_attempts_count: 0)
    end
    user.reload.second_factor_attempts_locked_at.nil? && otp == user.direct_otp
  end

  def generate_code(operation)
    user.update(
      second_factor_attempts_count: 0,
      direct_otp: random_base10(OTP_LENGTH),
      direct_otp_sent_at: Time.now.utc,
      secondary_authentication_operation: operation
    )
  end

  def send_secondary_authentication_code
    SendSecondaryAuthenticationJob.perform_later(user, user.direct_otp)
  end

  # def expiry_seconds
  #   TIMEOUTS[user.secondary_authentication_operation]
  # end

  def try_to_verify_user_mobile_number
    user.update(mobile_number_verified: true) unless user.mobile_number_verified
  end

  def try_to_unlock_secondary_authentication
    if user.second_factor_attempts_locked_at && (user.second_factor_attempts_locked_at + MAX_ATTEMPTS_COOLDOWN.seconds) < Time.now.utc
      user.update(second_factor_attempts_locked_at: nil)
    end
  end

  def operation
    user.secondary_authentication_operation
  end

  def direct_otp
    user.direct_otp
  end

private

  def random_base10(digits)
    SecureRandom.random_number(10**digits).to_s.rjust(digits, "0")
  end
end
