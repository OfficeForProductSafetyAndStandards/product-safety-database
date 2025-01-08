module ActiveModel
  module Types
    class GovukDate < ActiveRecord::Type::Value
      def cast(value)
        DateParser.new(value).date
      end
    end
  end
end
