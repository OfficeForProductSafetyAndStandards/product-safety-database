class ProductSubcategory < ApplicationRecord
  belongs_to :product_category

  validates :name, presence: true, uniqueness: { scope: :product_category }

  default_scope { order(:name) }

  redacted_export_with :id, :name, :product_category_id, :created_at, :updated_at
end
