class AuditActivity::Product::Add < AuditActivity::Product::Base
  def self.from(*)
    raise "Deprecated - use AddProductToCase.call instead"
  end

private

  def subtitle_slug
    "Product added"
  end
end
