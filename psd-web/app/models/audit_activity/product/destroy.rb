class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.from(*)
    raise "Deprecated - use RemoveProductFromCase.call instead"
  end

private

  def subtitle_slug
    "Product removed"
  end
end
