module SupportingInformation
  module TestResultSortInterface
    extend ActiveSupport::Concern

    def date_of_activity_sort
      date
    end
  end
end
