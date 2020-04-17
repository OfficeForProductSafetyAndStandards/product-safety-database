class TwoFactorAuthenticationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  INTEGER_REGEX = /\A\d+\z/.freeze

  attribute :otp_code
  attribute :secondary_authentication_id

  validates_presence_of :otp_code, message: I18n.t(".otp_code.blank")
  validates :otp_code,
            format: { with: INTEGER_REGEX, message: I18n.t(".otp_code.numericality") },
            allow_blank: true
  validates :otp_code,
            length: {
              maximum: SecondaryAuthentication::OTP_LENGTH,
              too_long: I18n.t(".otp_code.too_long"),
              minimum: SecondaryAuthentication::OTP_LENGTH,
              too_short: I18n.t(".otp_code.too_short")
            },
            allow_blank: true,
            if: -> { INTEGER_REGEX === otp_code }
  validate :correct_otp_validation

  def authenticate!
    secondary_authentication.authenticate!
  end

  def correct_otp_validation
    if secondary_authentication.direct_otp != self.otp_code
      errors.add(:otp_code, "Incorrect security code")
    end
  end

  def secondary_authentication
    SecondaryAuthentication.find_by(id: self.secondary_authentication_id)
  end
end
