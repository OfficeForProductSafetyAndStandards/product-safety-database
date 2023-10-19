class BulkProductsUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :user
  has_one_attached :products_file
end
