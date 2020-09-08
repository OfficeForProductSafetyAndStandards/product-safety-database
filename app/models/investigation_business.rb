class InvestigationBusiness < ApplicationRecord
  belongs_to :investigation
  belongs_to :business
  default_scope { order(created_at: :asc) }
  accepts_nested_attributes_for :business
end
