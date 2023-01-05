module AuditActivity
  module Correspondence
    class AddPhoneCallDecorator < AuditActivity::Correspondence::BaseDecorator
      def phone_number
        return if object.phone_number.blank?
        return object.phone_number if object.correspondent_name.blank?

        "(#{object.phone_number})"
      end

      def correspondence_date
        object.correspondence_date.to_formatted_s(:govuk)
      end

      def attached
        return if object.filename.blank?

        "Attached: #{object.filename}"
      end
    end
  end
end
