class AuditActivity::Product::Add < AuditActivity::Product::Base
private

  def subtitle_slug
    "Product added"
  end
end
