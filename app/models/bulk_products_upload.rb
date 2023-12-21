class BulkProductsUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :investigation_business, optional: true
  belongs_to :business, optional: true
  belongs_to :user
  has_and_belongs_to_many :products
  has_one_attached :products_file

  scope :incomplete, -> { where(submitted_at: nil) }

  def incomplete?
    submitted_at.nil?
  end

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

  # Called by a Sidekiq job on a cron schedule to destroy records that have been
  # abandoned before submission.
  def self.destroy_abandoned_records!
    BulkProductsUpload.where(submitted_at: nil).where("updated_at < ?", 3.days.ago).find_each(&:deep_destroy!)
  end
end
