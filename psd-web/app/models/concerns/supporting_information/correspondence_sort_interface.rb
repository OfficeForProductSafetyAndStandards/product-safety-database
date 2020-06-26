module SupportingInformation
  module CorrespondenceSortInterface
    extend ActiveSupport::Concern

    def date_of_activity_sort
      correspondence_date
    end
  end
end
