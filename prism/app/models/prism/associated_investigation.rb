module Prism
  class AssociatedInvestigation < ApplicationRecord
    belongs_to :risk_assessment
    belongs_to :investigation, class_name: "::Investigation"
    has_many :associated_investigation_products
  end
end
