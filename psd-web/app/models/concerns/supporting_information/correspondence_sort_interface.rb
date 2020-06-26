module SupportingInformation
  module CorrespondenceSortInterface
    extend ActiveSupport::Concern

    def supporting_information_title
      title
    end

    def date_of_activity_sort
      correspondence_date
    end
  end
end
