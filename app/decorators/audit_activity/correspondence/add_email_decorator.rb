module AuditActivity
  module Correspondence
    class AddEmailDecorator < AuditActivity::Correspondence::BaseDecorator
      def correspondence_date
        return Date.parse(metadata["correspondence_date"]).to_s(:govuk) if object.metadata

        object.correspondence_date
      end

      def title(_user)
        return object.metadata["overview"] if object.metadata

        object.title
      end
    end
  end
end
