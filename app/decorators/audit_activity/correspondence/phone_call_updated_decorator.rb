module AuditActivity
  module Correspondence
    class PhoneCallUpdatedDecorator < AuditActivity::Correspondence::BaseDecorator
      REMOVED = "Removed".freeze

      def new_correspondent_name
        return if metadata.dig("updates", "correspondent_name").blank?

        metadata.dig("updates", "correspondent_name", 1).presence || REMOVED
      end

      def new_phone_number
        return if metadata.dig("updates", "phone_number").blank?

        metadata.dig("updates", "phone_number", 1).presence || REMOVED
      end

      def new_correspondence_date
        Date.parse(metadata.dig("updates", "correspondence_date", 1)).to_s(:govuk)
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end

      def new_summary
        return if metadata.dig("updates", "overview").blank?

        metadata.dig("updates", "overview", 1).presence || REMOVED
      end

      def new_transcript
        metadata.dig("updates", "transcript")
      end

      def new_notes
        return if metadata.dig("updates", "details").blank?

        metadata.dig("updates", "details", 1).presence || REMOVED
      end
    end
  end
end
