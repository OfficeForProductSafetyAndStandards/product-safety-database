class AuditActivity::Product::Add < AuditActivity::Product::Base
  def self.from(product, investigation)
    title = product.name
    super(product, investigation, title)
  end

  def email_update_text(viewer = nil)
    "Product was added to the #{investigation.case_type} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Product added"
  end
end
