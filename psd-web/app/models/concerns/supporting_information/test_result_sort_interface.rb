module SupportingInformation
  module TestResultSortInterface
    extend ActiveSupport::Concern

    def supporting_information_title
      title
    end

    def date_of_activity_sort
      date
    end
  end
end
