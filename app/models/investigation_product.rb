class InvestigationProduct < ApplicationRecord
  belongs_to :investigation
  belongs_to :product

  enum affected_units_status: {
    "exact" => "exact",
    "approx" => "approx",
    "unknown" => "unknown",
    "not_relevant" => "not_relevant"
  }

  default_scope { order(created_at: :asc) }

  redacted_export_with :affected_units_status, :batch_number, :customs_code, :investigation_id, :number_of_affected_units, :product_id
end
