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
    return if @date.nil?

    if @date.is_a?(Date)
      parsed_date = @date
    elsif @date[:year].present? && @date[:month].present? && @date[:day].present?
      begin
        parsed_date = Date.new(@date[:year].to_i, @date[:month].to_i, @date[:day].to_i)
      rescue ArgumentError
        parsed_date = struct_from_hash
      end
    elsif @date[:year].present? || @date[:month].present? || @date[:day].present?
      parsed_date = struct_from_hash
    else
      parsed_date = nil
    end

    parsed_date
  end

private

  def struct_from_hash
    OpenStruct.new(year: @date[:year], month: @date[:month], day: @date[:day])
  end
end
