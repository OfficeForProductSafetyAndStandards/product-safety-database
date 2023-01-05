class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class EmailDecorator < CorrespondenceDecorator
    def title
      super || "Email on #{correspondence_date.to_formatted_s(:govuk)}"
    end

    def show_path
      h.investigation_email_path(investigation, object)
    end
  end
end
