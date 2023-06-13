require "aasm"

module Prism
  class RiskAssessment < ApplicationRecord
    include AASM

    has_one :product
    has_one :product_market_detail
    has_one :product_hazard
    has_many :harm_scenarios

    enum risk_type: {
      "prohibited_chemicals" => "prohibited_chemicals",
      "non_compliant_category_iii_ppe" => "non_compliant_category_iii_ppe",
      "assessed_by_opss_as_serious_risk" => "assessed_by_opss_as_serious_risk",
      "other" => "other",
    }

    enum assessed_before: {
      "yes" => "yes",
      "no" => "no",
      "dont_know" => "dont_know",
    }

    aasm do
      state :draft, initial: true
      state :assessment_details_completed
      state :existing_product_chosen
      state :product_market_details_completed
      state :product_hazards_completed
      state :product_harm_scenarios_completed
      state :submitted
    end
  end
end
