module ActiveModel
  module Types
    class BusinessList < ActiveRecord::Type::Value
      def cast(value)
        return value if value.all? { |b| b.is_a?(Business) }

        value.map { |business_attributes| Business.new(business_attributes) }
      end
    end
  end
end
