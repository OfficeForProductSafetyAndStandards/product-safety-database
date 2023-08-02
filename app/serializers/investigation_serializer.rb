class InvestigationSerializer < ActiveModel::Serializer
  attributes :type, :owner_id, :creator_id, :hazard_type,
             :description, :product_category, :is_closed, :updated_at, :created_at,
             :pretty_id, :hazard_description, :non_compliant_reason,
             :complainant_reference, :risk_level,
             :title, :product_subcategories, :product_barcodes, :product_descriptions, :product_codes
end
