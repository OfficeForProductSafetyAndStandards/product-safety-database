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

  redacted_export_with :id, :affected_units_status, :batch_number, :created_at,
                       :customs_code, :investigation_id, :number_of_affected_units,
                       :product_id, :updated_at

  def product
    investigation_closed_at ? super.paper_trail.version_at(investigation_closed_at) || super : super
  end

  def psd_ref
    product.psd_ref timestamp: investigation_closed_at&.to_i, investigation_was_closed: investigation_closed_at.present?
  end
end
