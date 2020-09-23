# Helper class which can parse a date from a hash of
# {day: "1", month: "2", year: "2020"}
#
# If the date is invalid, or any parts are missing, then
# the input date is returned as a struct
class DateParser
  def initialize(date)
    @date = date
  end

  def date
    return nil if @date.nil?
    return @date if @date.is_a?(Date)

    @date.symbolize_keys! if @date.respond_to?(:symbolize_keys!)

    date_values = @date.values_at(:year, :month, :day).map do |date_part|
      Integer(date_part)
    rescue StandardError
      nil
    end

    return nil if date_values.all?(&:blank?)
    return struct_from_hash if date_values.any?(&:blank?)

    begin
      Date.new(*date_values)
    rescue ArgumentError, RangeError
      struct_from_hash
    end
  end

private

  def struct_from_hash
    OpenStruct.new(year: @date[:year], month: @date[:month], day: @date[:day])
  end
end
