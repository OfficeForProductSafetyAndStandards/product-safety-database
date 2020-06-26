module SupportingInformation
  module CorrectiveActionSortInterface
    extend ActiveSupport::Concern

    def date_of_activity_sort
      date_decided
    end
  end
end
