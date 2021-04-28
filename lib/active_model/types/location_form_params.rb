module ActiveModel
  module Types
    class LocationFormParams < ActiveRecord::Type::Value
      def cast(location_form_params)
        return location_form_params if location_form_params.is_a?(LocationFormFields)

        LocationFormFields.new(location_form_params)
      end
    end
  end
end
