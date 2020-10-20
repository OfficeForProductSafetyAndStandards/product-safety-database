module AuditActivity
  module Correspondence
    class PhoneCallUpdatedDecorator < AuditActivity::Correspondence::BaseDecorator
      def new_correspondent_name
        metadata.dig("updates", "correspondent_name", 1)
      end

      def new_phone_number
        metadata.dig("updates", "phone_number", 1)
      end

      def new_correspondence_date
        Date.parse(metadata.dig("updates", "correspondence_date", 1)).to_s(:govuk)
      rescue StandardError # rubocop:disable Style/SuppressedException
      end

      def new_summary
        metadata.dig("updates", "overview", 1)
      end

      def new_transcript
        metadata.dig("updates", "transcript")
      end

      def new_notes
        metadata.dig("updates", "details", 1)
      end
    end
  end
end
