module AuditActivity
  module Correspondence
    class AddEmailDecorator < AuditActivity::Correspondence::BaseDecorator
      def correspondence_date
        Date.parse(metadata["correspondence_date"]).to_s(:govuk)
      end

      def subtitle_slug
        "Email recorded"
      end

      def restricted_title(_user)
        "Email added"
      end
    end
  end
end
