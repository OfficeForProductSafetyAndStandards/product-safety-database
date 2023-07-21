require "aasm"
require "store_attribute"

module Prism
  class RiskAssessment < ApplicationRecord
    include AASM

    has_one :product, autosave: true, dependent: :destroy
    has_one :product_market_detail, autosave: true, dependent: :destroy
    has_one :product_hazard, autosave: true, dependent: :destroy
    has_many :harm_scenarios, autosave: true, dependent: :destroy

    enum risk_type: {
      "normal_risk" => "normal_risk",
      "serious_risk" => "serious_risk",
    }

    store_attribute :routing_questions, :less_than_serious_risk, :boolean

    validates :risk_type, inclusion: %w[normal_risk serious_risk], on: :serious_risk
    validates :less_than_serious_risk, inclusion: [true, false], on: :serious_risk_rebuttable
    validates :serious_risk_rebuttable_factors, presence: true, if: -> { less_than_serious_risk }, on: :serious_risk_rebuttable
    validates :assessor_name, :assessment_organisation, presence: true, on: :add_assessment_details

    before_save :clear_serious_risk_rebuttable_factors

    # The state machine is used only on submission
    # Tasks within a risk assessment are handled by the wizard
    aasm column: :state do
      state :draft, initial: true
      state :submitted

      event :submit do
        transitions from: :draft, to: :submitted
      end
    end

  private

    def clear_serious_risk_rebuttable_factors
      self.serious_risk_rebuttable_factors = nil unless less_than_serious_risk
    end
  end
end
