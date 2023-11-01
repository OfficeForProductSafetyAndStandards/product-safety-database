class BulkProductsUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :investigation_business, optional: true
  belongs_to :business, optional: true
  belongs_to :user
  has_and_belongs_to_many :products
  has_one_attached :products_file

  # Destroys all records created as part of the bulk products upload process
  def deep_destroy!
    # Products created (as opposed to existing ones added to the investigation)
    source_products = Product.where(id: product_ids)

    investigation&.destroy!
    business&.destroy!
    products&.destroy_all
    source_products&.destroy_all
    destroy!
  end
end
