class TwoFactorAuthenticationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # From rails validations guide: https://guides.rubyonrails.org/active_record_validations.html#numericality
  NUMERICALITY_REGEX = /\A[+-]?\d+\z/.freeze

  attribute :otp_code

  validates_presence_of :otp_code, message: I18n.t(".otp_code.blank")
  validates :otp_code,
            numericality: { only_integer: true, message: I18n.t(".otp_code.numericality") },
            allow_blank: true
  validates :otp_code,
            length: { maximum: Devise.direct_otp_length, too_long: I18n.t(".otp_code.too_long") },
            allow_blank: true,
            if: -> { NUMERICALITY_REGEX === otp_code }
  validates :otp_code,
            length: { minimum: Devise.direct_otp_length, too_short: I18n.t(".otp_code.too_short") },
            allow_blank: true,
            if: -> { NUMERICALITY_REGEX === otp_code }
end
