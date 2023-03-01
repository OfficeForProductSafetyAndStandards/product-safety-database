class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.build_metadata(investigation_product, reason)
    {
      reason:,
      investigation_product: investigation_product.attributes
    }
  end

  def subtitle_slug
    "Product removed"
  end
end
