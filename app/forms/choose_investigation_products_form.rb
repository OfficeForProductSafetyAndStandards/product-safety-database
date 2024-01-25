class ChooseInvestigationProductsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :investigation_product_ids, default: []

  validates :investigation_product_ids, presence: true
end
