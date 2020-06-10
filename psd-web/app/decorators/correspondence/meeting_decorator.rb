class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class MeetingDecorator < CorrespondenceDecorator

    def title
      super || "Meeting on #{correspondence_date.to_s(:govuk)}"
    end
  end
end
