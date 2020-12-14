module ActiveModel
  module Types
    class CommaSeparatedList < ActiveRecord::Type::Value
      def cast(value)
        return value if value.is_a?(Array)
        return [] if value.nil? || value.blank?

        value.split(",").map(&:squish).select(&:present?)
      end
    end
  end
end
