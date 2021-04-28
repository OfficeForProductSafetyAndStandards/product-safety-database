module ActiveModel
  module Types
    class ContactFormParams < ActiveRecord::Type::Value
      def cast(contact_form_params)
        return contact_form_params if contact_form_params.is_a?(ContactFormFields)

        ContactFormFields.new(contact_form_params)
      end
    end
  end
end
