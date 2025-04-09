class BulkProductsUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :investigation_business, optional: true
  belongs_to :business, optional: true
  belongs_to :user
  has_and_belongs_to_many :products
  has_one_attached :products_file

  scope :incomplete, -> { where(submitted_at: nil) }

  def self.current_bulk_upload_template_path
    latest_file = ProductTaxonomyImport.completed.last&.bulk_upload_template_file

    if latest_file.present?
      Rails.application.routes.url_helpers.rails_storage_proxy_path(latest_file, only_path: true)
    else
      "/files/product_bulk_upload_template.xlsx"
    end
  end

  def incomplete?
    submitted_at.nil?
  end

  # Destroys all records created as part of the bulk products upload process
  def deep_destroy!
    # Products created (as opposed to existing ones added to the investigation)
    source_products = Product.where(id: product_ids)

    investigation&.destroy!
    products&.destroy_all
    source_products&.destroy_all
    destroy!
  end

  # Called by a Sidekiq job on a cron schedule to destroy records that have been
  # abandoned before submission.
  def self.destroy_abandoned_records!
    BulkProductsUpload.incomplete.where("updated_at < ?", 3.days.ago).find_each(&:deep_destroy!)
  end
end
