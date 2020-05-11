class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.from(product, investigation)
    title = "Removed: #{product.name}"
    super(product, investigation, title)
  end

  def email_update_text(viewer = nil)
    "Product was removed from the #{investigation.case_type} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Product removed"
  end
end
