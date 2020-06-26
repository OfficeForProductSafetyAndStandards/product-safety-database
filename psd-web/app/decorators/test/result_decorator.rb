class Test < ApplicationRecord
  require_dependency "test"
  class ResultDecorator < TestDecorator
    include SupportingInformation::TestResultSortInterface

    def title
      result_text = if passed?
                      "Passed test"
                    elsif failed?
                      "Failed test"
                    else
                      "Test result"
                    end

      "#{result_text}: #{product.name}"
    end

    def date_of_activity
      date.to_s(:govuk)
    end

    def date_added
      created_at.to_s(:govuk)
    end

    def supporting_information_type
      "Test result"
    end

    def show_path
      h.investigation_test_result_path(investigation, object)
    end

    def activity_cell_partial(_viewing_user)
      "activity_table_cell_with_link"
    end
  end
end
