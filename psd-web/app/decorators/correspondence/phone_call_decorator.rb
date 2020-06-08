class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class PhoneCallDecorator < InvestigationDecorator
    def title
      overview.presence || "Phone call on #{correspondence_date.to_s(:govuk)}"
    end
  end
end
