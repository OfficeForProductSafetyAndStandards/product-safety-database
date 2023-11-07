class DeleteAbandonedBulkProductsUploadsJob < ApplicationJob
  def perform
    BulkProductsUpload.destroy_abandoned_records!
  end
end
