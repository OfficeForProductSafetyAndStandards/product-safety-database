class BulkProductsChooseProductsForCorrectiveActionsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :random_uuid
  attribute :product_ids, default: []

  validates :product_ids, presence: true
end
