class PhoneValidator < ActiveModel::EachValidator
  ACCEPTED_PREFIXES = %w[7 07 447 4407 00447].freeze
  DEFAULT_ERROR = "is not a valid phone number".freeze
  MINIMUM_LENGTH = 10

  def validate_each(record, attribute, value)
    digits = value.delete("^0-9")

    if digits.length < MINIMUM_LENGTH || !digits.start_with?(*ACCEPTED_PREFIXES)
      record.errors[attribute] << (options[:message] || DEFAULT_ERROR)
    end
  end
end
