class RecentDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present? && value.is_a?(Date)

    on_or_after = options[:on_or_after] || Time.zone.parse("1970-01-01").to_date
    on_or_before = options[:on_or_before] || Time.zone.today + 50.years

    # NOTE: You can pass `false` to turn off the check, or `nil` to take the default
    if (!options[:on_or_after].is_a?(FalseClass) && value < on_or_after) ||
        (!options[:on_or_before].is_a?(FalseClass) && value > on_or_before)
      record.errors.add(attribute, options[:message] || :recent_date)
    end
  end
end
