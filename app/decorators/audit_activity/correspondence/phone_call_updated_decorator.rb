module AuditActivity
  module Correspondence
    class PhoneCallUpdatedDecorator < AuditActivity::Correspondence::BaseDecorator
      REMOVED = "removed".freeze
      EMPTY_ENQUIRY = ActiveSupport::StringInquirer.new("").freeze

      def title(_viewing_user = nil)
        new_summary
      end

      def new_correspondent_name
        return EMPTY_ENQUIRY if metadata.dig("updates", "correspondent_name").blank?

        updated_text_for("correspondent_name")
      end

      def new_phone_number
        return EMPTY_ENQUIRY if metadata.dig("updates", "phone_number").blank?

        updated_text_for("phone_number")
      end

      def new_correspondence_date
        Date.parse(metadata.dig("updates", "correspondence_date", 1)).to_formatted_s(:govuk)
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end

      def new_summary
        return EMPTY_ENQUIRY if metadata.dig("updates", "overview").blank?

        updated_text_for("overview")
      end

      def new_transcript
        metadata.dig("updates", "transcript")
      end

      def new_notes
        return EMPTY_ENQUIRY if metadata.dig("updates", "details").blank?

        updated_text_for("details")
      end

    private

      def updated_text_for(attribute)
        ActiveSupport::StringInquirer.new(metadata.dig("updates", attribute, 1).presence || REMOVED)
      end
    end
  end
end
