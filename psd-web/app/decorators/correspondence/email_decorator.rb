class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class EmailDecorator < InvestigationDecorator
    def title
      overview.presence || correspondence_date.to_s(:govuk)
    end
  end
end
