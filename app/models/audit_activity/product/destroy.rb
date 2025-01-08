class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.build_metadata(investigation_product, reason)
    {
      reason:,
      product: investigation_product.product.attributes
    }
  end

  def subtitle_slug
    "Product removed"
  end
end
