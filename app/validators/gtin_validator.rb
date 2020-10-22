# Validate a Global Trade Idem Number
#
class GtinValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    begin
      gtin = Barkick::GTIN.new(value)
      # 8 digit codes raise an ArgumentError, as a type (UPC-E or EAN-8) needs
      # to be specified in order to convert the code to a valid GTIN
    rescue ArgumentError
      return
    end

    unless gtin.valid?
      record.errors.add(attribute, :invalid)
    end
  end
end
