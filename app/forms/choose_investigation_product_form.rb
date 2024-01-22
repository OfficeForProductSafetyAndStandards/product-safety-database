class ChooseInvestigationProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :investigation_product_id

  validates :investigation_product_id, presence: true
end
