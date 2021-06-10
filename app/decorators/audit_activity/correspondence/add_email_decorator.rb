module AuditActivity
  module Correspondence
    class AddEmailDecorator < AuditActivity::Correspondence::BaseDecorator
      def correspondence_date
        Date.parse(metadata["correspondence_date"]).to_s(:govuk)
      end
    end
  end
end
