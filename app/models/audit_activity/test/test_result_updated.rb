class AuditActivity::Test::TestResultUpdated < AuditActivity::Test::Base
  def self.from(*)
    raise "Deprecated - use UpdateTestResult.call instead"
  end

  def self.build_metadata(test_result)
    updated_values = test_result
      .previous_changes.slice(:result, :details, :legislation, :date, :product_id)

    current_attachment = test_result.document

    if test_result.document_blob.previous_changes.any?
      previous_attachment_filename = test_result.document_blob.previous_changes.dig("filename", 1)
      previous_attachment_description = test_result.document_blob.previous_changes.dig("metadata", 1, "description")

      if previous_attachment_filename != current_attachment.filename
        updated_values["filename"] = [previous_attachment_filename, test_result.document.filename]
      end

      if previous_attachment_description != current_attachment.metadata[:description]
        updated_values["file_description"] = [previous_attachment_description, current_attachment.metadata[:description]]
      end
    end

    { test_result_id: test_result.id, updates: updated_values }
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
    updates["details"]&.second
  end

  def new_legislation
    updates["legislation"]&.second
  end

  def new_filename
    updates["filename"]&.second
  end

  def new_file_description
    updates["file_description"]&.second
  end

  def new_product
    @new_product ||=
      if updates["product_id"]
        Product.find(updates["product_id"].second)
      end
  end

private

  def updates
    metadata["updates"]
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
