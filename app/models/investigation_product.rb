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

  def versioned_product_subcategory
    investigation_closed_at ? product.paper_trail.version_at(investigation_closed_at).subcategory : product.subcategory
  end

  def versioned_product_barcode
    investigation_closed_at ? product.paper_trail.version_at(investigation_closed_at).barcode : product.barcode
  end

  def versioned_product_description
    investigation_closed_at ? product.paper_trail.version_at(investigation_closed_at).description : product.description
  end

  def versioned_product_code
    investigation_closed_at ? product.paper_trail.version_at(investigation_closed_at).product_code : product.product_code
  end
end
