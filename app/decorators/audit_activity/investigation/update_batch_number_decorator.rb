class AuditActivity::Investigation::UpdateBatchNumberDecorator < ApplicationDecorator
  delegate_all

  def new_batch_number
    metadata.dig("updates", "batch_number", 1)
  end

  def title(_viewer)
    "Batch number updated"
  end
end
