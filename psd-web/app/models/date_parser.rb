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
    return nil if @date[:year].blank? && @date[:month].blank? && @date[:day].blank?

    if numeric?(@date[:year]) && numeric?(@date[:month]) && numeric?(@date[:day])
      begin
        Date.new(@date[:year].to_i, @date[:month].to_i, @date[:day].to_i)
      rescue ArgumentError, RangeError
        struct_from_hash
      end
    else
      struct_from_hash
    end
  end

private

  # Checks that the string contains only digits (once leading/trailing whitespace is snipped)
  # as otherwise `to_i` can return expected results, eg `"2??9".to_i == 2`
  def numeric?(string)
    string.to_s.strip.scan(/^[\d]+$/).any?
  end

  def struct_from_hash
    OpenStruct.new(year: @date[:year], month: @date[:month], day: @date[:day])
  end
end
