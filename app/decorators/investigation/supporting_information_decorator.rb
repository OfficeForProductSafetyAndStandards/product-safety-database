class Investigation < ApplicationRecord
  class SupportingInformationDecorator
    include ActionView::Helpers::TranslationHelper

    delegate :any?, :none?, :size, :each, :to_a, to: :@supporting_information

    DATE_OF_ACTIVITY = :date_of_activity
    DATE_ADDED       = :date_added
    TITLE            = :title

    SORT_OPTIONS = [DATE_OF_ACTIVITY, DATE_ADDED, TITLE].freeze

    def initialize(supporting_information, param_sort_by)
      @sort_by = param_sort_by || :date_added
      @supporting_information = supporting_information
      sort
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
        sort_desc(:date_of_activity_for_sorting)
      when DATE_ADDED
        sort_desc(:created_at)
      when TITLE
        sort_string_asc(:supporting_information_title)
      end
    end

    def sort_string_asc(field)
      @supporting_information.sort! { |a, b| a.public_send(field).downcase <=> b.public_send(field).downcase }
    end

    def sort_desc(field)
      @supporting_information.sort! { |a, b| b.public_send(field) <=> a.public_send(field) }
    end
  end
end
