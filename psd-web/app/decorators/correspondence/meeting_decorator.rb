class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class MeetingDecorator < CorrespondenceDecorator
    def title
      super || "Meeting on #{correspondence_date.to_s(:govuk)}"
    end

    def show_path
      h.investigation_meeting_path(investigation, object)
    end
  end
end
