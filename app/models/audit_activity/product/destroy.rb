class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.build_metadata(product, reason)
    { reason:, product: product.attributes }
  end

private

  def subtitle_slug
    "Product removed"
  end
end
