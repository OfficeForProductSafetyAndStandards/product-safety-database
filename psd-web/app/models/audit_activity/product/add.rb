class AuditActivity::Product::Add < AuditActivity::Product::Base
  def self.from(product, investigation)
    title = product.name
    super(product, investigation, title)
  end

  def email_update_text(viewing_user = nil)
    "Product was added to the #{investigation.case_type} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Product added"
  end
end
