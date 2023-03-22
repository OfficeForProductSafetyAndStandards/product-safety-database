class AuditActivity::Test::Result < AuditActivity::Test::Base
  def self.build_metadata(test_result)
    { "test_result" => test_result.attributes.merge(
      "document" => test_result.document.blob.attributes
    ) }
  end

  # TODO: remove once migrated
  def metadata
    migrate_metadata_structure
  end

  def test_result
    return if metadata.nil?

    @test_result ||= Test::Result.find(metadata["test_result"]["id"])
  end

  def attached_file
    ActiveStorage::Blob.find(metadata["test_result"]["document"]["id"])
  end

  def attached_file_name
    metadata["test_result"]["document"]["filename"]
  end

  def legislation
    metadata["test_result"]["legislation"]
  end

  def standards_product_was_tested_against
    metadata["test_result"]["standards_product_was_tested_against"]
  end

  def result
    metadata["test_result"]["result"]
  end

  def failure_details
    metadata["test_result"]["failure_details"]
  end

  def details
    metadata["test_result"]["details"]
  end

  def date
    return if metadata["test_result"]["date"].nil?

    Date.parse(metadata["test_result"]["date"])
  end

private

  def subtitle_slug
    "Test result recorded"
  end

  # TODO: remove once migrated
  def migrate_metadata_structure
    metadata = self[:metadata] || {}

    product_id = metadata.dig("test_result", "product_id")
    return metadata if product_id.blank?

    metadata["test_result"]["investigation_product_id"] = investigation.investigation_products.where(product_id:).pick("investigation_products.id")
    metadata["test_result"].delete("product_id")
    metadata
  end
end
