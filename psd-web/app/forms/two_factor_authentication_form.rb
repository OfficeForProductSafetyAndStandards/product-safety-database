class TwoFactorAuthenticationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :otp_code

  validates_presence_of :otp_code, message: I18n.t(".otp_code.blank")
  validates :otp_code,
            length: { maximum: Devise.direct_otp_length, too_long: I18n.t(".otp_code.too_long") },
                    if: ->(form) { form.otp_code.present? }
  validates :otp_code,
            length: { minimum: Devise.direct_otp_length, too_short: I18n.t(".otp_code.too_short") },
                    if: ->(form) { form.otp_code.present? }
end
