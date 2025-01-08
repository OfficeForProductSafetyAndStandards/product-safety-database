module Prism
  class AssociatedProduct < ApplicationRecord
    belongs_to :risk_assessment
    belongs_to :product, class_name: "::Product"
  end
end
