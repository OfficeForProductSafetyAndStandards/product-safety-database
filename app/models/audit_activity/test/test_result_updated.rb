class AuditActivity::Test::TestResultUpdated < AuditActivity::Test::Base
  def self.build_metadata(test_result, changes)
    updates = changes.except("document", "existing_document_file_id")

    {
      test_result_id: test_result.id,
      updates:
    }
  end

  def title(_)
    "Test result"
  end

  def subtitle_slug
    "Edited"
  end

  def test_result
    ::Test::Result.find(metadata["test_result_id"])
  end

  def new_date_of_test
    if updates["date"]
      Date.parse(updates["date"].second)
    end
  end

  def new_result
    updates["result"]&.second
  end

  def new_details
    if updates["details"]&.second
      updates["details"]&.second.presence || "Removed"
    end
  end

  def new_legislation
    updates["legislation"]&.second
  end

  def new_filename
    updates["filename"]&.second
  end

  def new_file_description
    if updates["file_description"]&.second
      updates["file_description"]&.second.presence || "Removed"
    end
  end

  def new_standards_product_was_tested_against
    updates["standards_product_was_tested_against"]&.second
  end

  def new_failure_details
    updates["failure_details"]&.second
  end

  def show_new_failure_details?
    new_failure_details && test_result.result == "failed"
  end

  def new_product
    @new_product ||=
      if updates["investigation_product_id"]
        InvestigationProduct.find(updates["investigation_product_id"].second)
      end
  end

private

  def updates
    metadata["updates"]
  end
end
