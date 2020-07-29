class DateForm < ActiveModel::Type::Value
  def cast(value)
    return value if value.is_a?(Date)

    date_parts = value.values_at(:year, :month, :day)
    date_parts.compact!
    date_parts.map!(&:to_i)

    return nil if date_parts.size != 3

    Date.new(*date_parts)
  end
end
