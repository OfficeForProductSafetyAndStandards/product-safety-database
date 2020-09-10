module ActiveModel
  module Types
    class BusinessList < ActiveRecord::Type::Value
      def cast(value)
        value.map { |business_attributes| Business.new(business_attributes) }
      end
    end
  end
end
