class PrismAssociatedInvestigationProduct < ApplicationRecord
  belongs_to :prism_associated_investigation, foreign_key: "associated_investigation_id"
  belongs_to :product
end
