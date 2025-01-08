class SendSMS
  TEMPLATES = {
    otp_code: "091c8861-8532-4907-abc0-f89632c34f09"
  }.freeze

  Phonelib.default_country = "GB"
  UK_PREFIX = "+44".freeze
  UK_LEADING_ZERO = /\A0/

  attr_reader :client

  def initialize(strict: true)
    @client = Notifications::Client.new(Rails.configuration.notify_api_key)
    Phonelib.strict_check = strict
  end

  def self.otp_code(mobile_number:, code:, strict: true)
    new(strict:).otp_code(mobile_number:, code:)
  end

  def otp_code(mobile_number:, code:)
    if (formatted_number = validate_and_format_phone_number(mobile_number))
      client.send_sms(
        phone_number: formatted_number,
        template_id: TEMPLATES[:otp_code],
        personalisation: { code: }
      )
    end
  end

private

  def validate_and_format_phone_number(phone_number)
    return nil if phone_number.nil?

    normalized_number = normalize_uk_number(phone_number)
    return nil unless valid_phone_number?(normalized_number)

    normalized_number
  end

  def normalize_uk_number(phone_number)
    cleaned_number = phone_number.gsub(/[\s-]+/, "")

    cleaned_number = cleaned_number.sub(/\A00/, "+")

    return cleaned_number if cleaned_number.start_with?(UK_PREFIX)

    if cleaned_number.match?(UK_LEADING_ZERO)
      return UK_PREFIX + cleaned_number.gsub(UK_LEADING_ZERO, "")
    end

    UK_PREFIX + cleaned_number
  end

  def valid_phone_number?(phone_number)
    Phonelib.parse(phone_number).valid?
  end
end
