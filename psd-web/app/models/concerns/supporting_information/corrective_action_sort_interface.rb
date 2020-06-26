module SupportingInformation
  module CorrectiveActionSortInterface
    extend ActiveSupport::Concern

    def supporting_information_title
      summary
    end

    def date_of_activity_sort
      date_decided
    end
  end
end
