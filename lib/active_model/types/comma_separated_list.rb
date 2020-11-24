module ActiveModel
  module Types
    class CommaSeparatedList < ActiveRecord::Type::Value
      def cast(value)
        return [] if value.nil?

        value.split(",").map(&:squish)
      end
    end
  end
end
