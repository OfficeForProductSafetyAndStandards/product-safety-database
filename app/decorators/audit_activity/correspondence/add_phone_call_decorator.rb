module AuditActivity
  module Correspondence
    class AddPhoneCallDecorator < AuditActivity::Correspondence::BaseDecorator

      def title(_viewing_user)
        "summary of the phone call"
      end

      def phone_call_by(viewing_user)
        return if correspondence.correspondent_name.blank?

        Activity.sanitize_text("#{subtitle(viewing_user)}")
      end

      def phone_number
        return if correspondence.phone_number.blank?
        return correspondence.phone_number if correspondence.correspondent_name.blank?

        "(#{correspondence.phone_number})"
      end

      def correspondence_date
        correspondence.correspondence_date.to_s(:govuk)
      end

      def attached
        return if correspondence.transcript.blank?

        "Attached: #{correspondence.transcript_blob.filename}"
      end
    end
  end
end
