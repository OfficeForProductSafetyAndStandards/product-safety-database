class Test < ApplicationRecord
  require_dependency "test"
  class ResultDecorator < TestDecorator
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

    def supporting_information_title
      title
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
  end
end
