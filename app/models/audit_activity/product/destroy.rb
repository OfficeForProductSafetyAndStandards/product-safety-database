class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.build_metadata(product, reason)
    { reason: reason, product: product.attributes }
  end

  def self.from(*)
    raise "Deprecated - use RemoveProductFromCase.call instead"
  end

private

  def subtitle_slug
    "Product removed"
  end
end
