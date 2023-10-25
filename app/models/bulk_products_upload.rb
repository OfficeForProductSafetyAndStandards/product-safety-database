class BulkProductsUpload < ApplicationRecord
  belongs_to :investigation, dependent: :destroy
  belongs_to :investigation_business, optional: true, dependent: :destroy
  belongs_to :user
  has_one_attached :products_file
end
