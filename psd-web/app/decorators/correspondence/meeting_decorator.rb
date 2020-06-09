class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class MeetingDecorator < ApplicationDecorator
    include SupportingInformationHelper

    def title
      overview.presence || "Meeting on #{correspondence_date.to_s(:govuk)}"
    end
  end
end
