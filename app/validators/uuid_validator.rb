class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless /^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$/i.match?(value)
      record.errors.add(attribute, :invalid, message: options[:message] || "is not a valid UUID")
    end
  end
end
