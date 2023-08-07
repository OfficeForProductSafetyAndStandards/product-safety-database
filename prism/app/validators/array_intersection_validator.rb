# Inspired by https://github.com/rafaelbiriba/active_model_validates_intersection_of

class ArrayIntersectionValidator < ActiveModel::EachValidator
  def check_validity!
    unless delimiter.respond_to?(:include?) || delimiter.respond_to?(:call) || delimiter.respond_to?(:to_sym)
      raise ArgumentError, "An object with the method #include? or a proc, lambda or symbol is required, and must be supplied as the :in (or :within) option"
    end
  end

  def validate_each(record, attribute, value)
    raise ArgumentError, "value must be an array" unless value.is_a?(Array)

    if (value - members(record)).size.positive?
      record.errors.add(attribute, :inclusion)
    end
  end

private

  def members(record)
    if delimiter.respond_to?(:call)
      delimiter.call(record)
    elsif delimiter.respond_to?(:to_sym)
      record.send(delimiter)
    else
      delimiter
    end
  end

  def delimiter
    @delimiter ||= options[:in] || options[:within]
  end
end
