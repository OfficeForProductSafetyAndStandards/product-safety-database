module AuditActivity
  module Correspondence
    class AddEmailDecorator < AuditActivity::Correspondence::BaseDecorator
      def correspondence_date
        Date.parse(metadata["correspondence_date"]).to_formatted_s(:govuk) if object.metadata
      end

      def title(_user)
        object.metadata["overview"] if object.metadata
      end
    end
  end
end
