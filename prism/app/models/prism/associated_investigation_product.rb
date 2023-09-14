module Prism
  class AssociatedInvestigationProduct < ApplicationRecord
    belongs_to :associated_investigation
    belongs_to :product, class_name: "::Product"
  end
end
