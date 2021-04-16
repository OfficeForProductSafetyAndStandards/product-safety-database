module ActiveModel
  module Types
    class CreatedBySearchParams < ActiveRecord::Type::Value
      def cast(created_by_search_params)
        return created_by_search_params if created_by_search_params.is_a?(CreatedBySearchFormFields)

        CreatedBySearchFormFields.new(created_by_search_params)
      end
    end
  end
end
