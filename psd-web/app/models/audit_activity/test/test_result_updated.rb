class AuditActivity::Test::TestResultUpdated < AuditActivity::Test::Base
  def self.from(*)
    raise "Deprecated - use UpdateTestResult.call instead"
  end

  def self.build_metadata(test_result)
    updated_values = test_result
      .previous_changes.slice(:result, :details, :legislation, :date, :product_id)

    {
      test_result_id: test_result.id,
      updates: updated_values
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
      Date.parse(updates["date"][1])
    end
  end

  def new_result
    if updates["result"]
      updates["result"][1]
    end
  end

  def new_details
    if updates["details"]
      updates["details"][1]
    end
  end

  def new_legislation
    if updates["legislation"]
      updates["legislation"][1]
    end
  end

  def new_product
    @new_product ||=
      if updates["product_id"]
        Product.find(updates["product_id"][1])
      end
  end

private

  def updates
    metadata["updates"]
  end
end
