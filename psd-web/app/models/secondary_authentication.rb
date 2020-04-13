class SecondaryAuthentication < ApplicationRecord
  RESET_PASSWORD = "reset_password"
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
    update(authenticated: true)
  end

  def expired?
    direct_otp_sent_at < (Time.now.utc - valid_for_seconds.seconds)
  end

  # TODO: make dependend from operation type
  def valid_for_seconds
    candidate = {
      "passwords/edit" => 300,
    }[self.operation]

    candidate || 300
  end

  private

  def random_base10(digits)
    SecureRandom.random_number(10**digits).to_s.rjust(digits, '0')
  end
end
