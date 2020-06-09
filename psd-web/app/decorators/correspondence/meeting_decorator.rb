class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class MeetingDecorator < InvestigationDecorator
    def title
      overview.presence || "Meeting on #{correspondence_date.to_s(:govuk).lstrip}"
    end
  end
end
