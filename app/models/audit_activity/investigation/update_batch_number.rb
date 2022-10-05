class AuditActivity::Investigation::UpdateBatchNumber < AuditActivity::Investigation::Base
  def self.build_metadata(investigation_product)
    updated_values = investigation_product.previous_changes.slice(:batch_number)

    {
      updates: updated_values
    }
  end
end
