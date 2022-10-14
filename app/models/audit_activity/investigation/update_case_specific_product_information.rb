class AuditActivity::Investigation::UpdateCaseSpecificProductInformation < AuditActivity::Investigation::Base
  def self.build_metadata(investigation_product)
    updated_values = investigation_product.previous_changes.slice(:batch_number, :customs_code, :affected_units_status, :number_of_affected_units)

    {
      updates: updated_values
    }
  end
end
