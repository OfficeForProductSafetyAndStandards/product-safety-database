class Investigation < ApplicationRecord
  class SupportingInformationDecorator
    include ActionView::Helpers::TranslationHelper

    DATE_OF_ACTIVITY = :date_of_activity
    DATE_ADDED       = :date_added
    TITLE            = :title

    SORT_OPTIONS = [DATE_OF_ACTIVITY, DATE_ADDED, TITLE]

    def initialize(supporting_information, param_sort_by)
      @sort_by = (param_sort_by || :date_of_activity)
      @supporting_information = supporting_information.map(&:decorate)
      sort
    end

    def any?
      @supporting_information.any?
    end

    def to_a
      @supporting_information.to_a
    end

    def none?
      @supporting_information.none?
    end

    def sort_by
      @sort_by.to_sym
    end

    def sort_items
      SORT_OPTIONS.map { |option| { text: t("supporting_information.sorting.#{option}"), value: option, selected: (option == sort_by) } }
    end

    private

    def sort
      case sort_by
      when DATE_OF_ACTIVITY
        @supporting_information.sort_by!(&:date_of_activity)
      when DATE_ADDED
        @supporting_information.sort_by!(&:created_at)
      when TITLE
        @supporting_information.sort_by!(&:supporting_information_title)
      end
    end
  end
end
