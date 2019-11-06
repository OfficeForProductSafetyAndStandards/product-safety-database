class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      record.errors[attribute] << (options[:message] || "is not a valid UUID")
    end
  end
end
