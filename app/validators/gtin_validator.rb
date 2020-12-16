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
      gtin = Barkick::GTIN.new(record.public_send(attribute), type: :upc_e)
      gtin = Barkick::GTIN.new(record.public_send(attribute), type: :ean8) unless gtin.valid?
    end

    unless gtin.valid?
      record.errors.add(attribute, :invalid) unless record.errors.of_kind?(attribute, :wrong_length)
    end
  end
end
