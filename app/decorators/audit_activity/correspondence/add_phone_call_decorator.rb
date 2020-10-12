module AuditActivity
  module Correspondence
    class AddPhoneCallDecorator < AuditActivity::Correspondence::BaseDecorator
      def phone_call_by(viewing_user)
        return if correspondence.correspondent_name.blank?

        Activity.sanitize_text("#{subtitle(viewing_user)}")
      end

      def phone_number
        return if correspondence.phone_number.blank?

        correspondence.phone_number.yield_self do |s|
          correspondence.correspondent_name.present? ? "(#{s})" : s
        end
      end

      def correspondence_date
        "Date: #{correspondence.correspondence_date.to_s(:govuk)}"
      end

      def attached
        return if correspondence.transcript.blank?
        "Attached: #{correspondence.transcript_blob.filename}"
      end
    end
  end
end
