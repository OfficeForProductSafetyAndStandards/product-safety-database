class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class EmailDecorator < ApplicationDecorator
    include SupportingInformationHelper

    def title
      overview.presence || "Email on #{correspondence_date.to_s(:govuk)}"
    end
  end
end
