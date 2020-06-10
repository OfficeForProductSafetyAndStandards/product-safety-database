class Correspondence < ApplicationRecord
  require_dependency "correspondence"
  class PhoneCallDecorator < CorrespondenceDecorator

    def title
      super || "Phone call on #{correspondence_date.to_s(:govuk)}"
    end
  end
end
