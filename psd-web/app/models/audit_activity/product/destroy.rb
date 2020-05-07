class AuditActivity::Product::Destroy < AuditActivity::Product::Base
  def self.from(product, investigation)
    title = "Removed: #{product.name}"
    super(product, investigation, title)
  end

  def email_update_text(viewing_user = nil)
    "Product was removed from the #{investigation.case_type} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Product removed"
  end
end
