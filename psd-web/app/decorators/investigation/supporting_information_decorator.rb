class Investigation < ApplicationRecord
  class SupportingInformationDecorator
    include ActionView::Helpers::TranslationHelper

    DATE_OF_ACTIVITY = :date_of_activity
    DATE_ADDED       = :date_added
    TITLE            = :title

    SORT_OPTIONS = [DATE_OF_ACTIVITY, DATE_ADDED, TITLE].freeze

    def initialize(supporting_information, param_sort_by)
      @sort_by = (param_sort_by || :date_added)
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

    def sort_options
      SORT_OPTIONS.map { |option| { text: t("supporting_information.sorting.#{option}"), value: option, selected: (option == sort_by) } }
    end

  private

    def sort
      case sort_by
      when DATE_OF_ACTIVITY
        sort_desc(:date_of_activity)
      when DATE_ADDED
        sort_desc(:created_at)
      when TITLE
        sort_asc(:supporting_information_title)
      end
    end

    def sort_asc(field)
      @supporting_information.sort! { |a,b| a.send(field) <=> b.send(field) }
    end

    def sort_desc(field)
      @supporting_information.sort! { |a,b| b.send(field) <=> a.send(field) }
    end
  end
end
