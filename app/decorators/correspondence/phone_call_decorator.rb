class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class PhoneCallDecorator < CorrespondenceDecorator
    def title
      super || "Phone call on #{correspondence_date.to_formatted_s(:govuk)}"
    end

    def show_path
      h.investigation_phone_call_path(investigation, object)
    end
  end
end
