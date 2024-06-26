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

      "#{result_text}: #{investigation_product&.name}"
    end

    def result_text
      if passed?
        "Passed test"
      elsif failed?
        "Failed test"
      else
        "Test result"
      end
    end

    def product_tested
      "#{investigation_product.name} (#{investigation_product.psd_ref})"
    end

    def attachment_description
      return "No description available" if document.nil?

      description = document.blob&.metadata&.fetch("description", nil)
      description || "No description available"
    end

    def supporting_information_title
      title
    end

    def date_of_activity
      date&.to_formatted_s(:govuk)
    end

    def date_of_activity_for_sorting
      date
    end

    def date_added
      created_at.to_formatted_s(:govuk)
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

    def standards_product_was_tested_against
      object.standards_product_was_tested_against&.join(", ")
    end

    def failure_details
      return "Not provided" if object.failure_details.nil?

      object.failure_details
    end

    def event_type
      return "Pass" if passed?
      return "Fail" if failed?

      supporting_information_type
    end

    def is_attached_to_versioned_product?
      !!investigation_closed_at
    end

    def investigation_closed_at
      object.investigation_product.investigation_closed_at
    end

    def psd_ref
      object.investigation_product.psd_ref
    end

    def opss_funded?
      object.tso_certificate_issue_date.present?
    end

    def funding_issue_date
      object.tso_certificate_issue_date.to_formatted_s(:govuk)
    end

    def case_id
      object.investigation.pretty_id
    end
  end
end
