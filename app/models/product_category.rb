class ProductCategory < ApplicationRecord
  has_many :product_subcategories, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }

  redacted_export_with :id, :name, :created_at, :updated_at
end
