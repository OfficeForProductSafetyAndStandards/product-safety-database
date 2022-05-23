class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.build_metadata(product, reason)
    { reason:, product: product.attributes }
  end

  def metadata
    migrate_metadata_structure
  end

private

  def subtitle_slug
    "Product removed"
  end

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if already_in_new_format?

    JSON.parse({
      "reason" => self[:title],
      "product" => product.attributes
    }.to_json)
  end

  def already_in_new_format?
    self[:metadata]&.key?("product")
  end
end
