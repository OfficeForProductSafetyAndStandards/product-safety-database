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

    Phonelib.parse(normalized_number).international
  end

  def normalize_uk_number(phone_number)
    return phone_number if phone_number.start_with?(UK_PREFIX)

    # If number starts with 0, remove it and add +44
    if phone_number.match?(UK_LEADING_ZERO)
      return UK_PREFIX + phone_number.gsub(UK_LEADING_ZERO, "")
    end

    # If number doesn't start with + or 0, assume it needs +44
    UK_PREFIX + phone_number
  end

  def valid_phone_number?(phone_number)
    parsed_number = Phonelib.parse(phone_number)
    parsed_number.valid? && parsed_number.country_code == "44" # Ensure it's a UK number
  end
end
