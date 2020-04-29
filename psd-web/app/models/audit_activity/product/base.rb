class AuditActivity::Product::Base < AuditActivity::Base
  belongs_to :product

  private_class_method def self.from(product, investigation, title)
    create(
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: title,
      product: product
    )
  end
end
