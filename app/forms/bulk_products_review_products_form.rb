class BulkProductsReviewProductsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :random_uuid
  attribute :images, default: {}
end
