class InvestigationBusiness < ApplicationRecord
  belongs_to :investigation
  belongs_to :business
  belongs_to :online_marketplace, optional: true

  default_scope { order(created_at: :desc) }

  redacted_export_with :id, :business_id, :created_at, :investigation_id,
                       :relationship, :updated_at
end
