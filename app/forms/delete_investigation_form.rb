class DeleteInvestigationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :investigation

  validates :investigation, presence: true
  validate :investigation_has_no_products

  def investigation_has_no_products
    errors.add(:has_products, "Cannot delete a case with products") unless investigation && investigation.products.none?
  end
end
