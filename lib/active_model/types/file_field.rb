module ActiveModel
  module Types
    class FileField < ActiveRecord::Type::Value
      def cast(value)
        return value if value.is_a?(ActiveStorage::Blob)
        return nil unless value.key?(:file)

        ::FileField.new(value)
      end
    end
  end
end
