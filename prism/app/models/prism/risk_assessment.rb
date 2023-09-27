require "aasm"
require "store_attribute"

module Prism
  class RiskAssessment < ApplicationRecord
    include AASM

    has_one :product_market_detail, autosave: true, dependent: :destroy
    has_one :product_hazard, autosave: true, dependent: :destroy
    has_many :harm_scenarios, autosave: true, dependent: :destroy
    has_one :evaluation, autosave: true, dependent: :destroy
    has_many :associated_products, autosave: true, dependent: :destroy
    has_many :associated_investigations, autosave: true, dependent: :destroy
    has_many :associated_investigation_products, through: :associated_investigations, autosave: true, dependent: :destroy

    # This is used on the "Review the overall product risk level"
    # page in case there are no other fields to make strong params
    # work.
    attribute :_dummy, :string

    enum risk_type: {
      "normal_risk" => "normal_risk",
      "serious_risk" => "serious_risk",
    }

    enum overall_product_risk_methodology: {
      "highest": "highest",
      "combined": "combined",
    }

    enum overall_product_risk_level: {
      "low" => "low",
      "medium" => "medium",
      "high" => "high",
      "serious" => "serious",
    }

    store_attribute :routing_questions, :less_than_serious_risk, :boolean
    store_attribute :routing_questions, :triage_complete, :boolean

    validates :risk_type, inclusion: %w[normal_risk serious_risk], on: :serious_risk
    validates :less_than_serious_risk, inclusion: [true, false], on: :serious_risk_rebuttable
    validates :serious_risk_rebuttable_factors, presence: true, if: -> { less_than_serious_risk }, on: :serious_risk_rebuttable
    validates :assessor_name, :assessment_organisation, presence: true, on: %i[add_assessment_details add_evaluation_details]
    validates :name, presence: true, uniqueness: true, on: %i[add_assessment_details add_evaluation_details]
    validate :check_all_harm_scenarios, on: :confirm_overall_product_risk
    validates :overall_product_risk_methodology, inclusion: %w[highest combined], if: -> { multiple_harm_scenarios_with_identical_severity_levels? }, on: :confirm_overall_product_risk

    before_save :clear_serious_risk_rebuttable_factors
    before_save :clear_overall_product_risk_plus_label
    before_save :clear_overall_product_risk_methodology

    aasm column: :state, whiny_transitions: false do
      state :draft, initial: true
      state :define_completed
      state :identify_completed
      state :create_completed
      state :submitted

      event :complete_define_section do
        # Serious risk workflow skips from define to evaluate
        transitions from: :draft, to: :create_completed do
          guard do
            serious_risk?
          end
        end
        transitions from: :draft, to: :define_completed
      end

      event :complete_identify_section do
        transitions from: :define_completed, to: :identify_completed
      end

      event :complete_create_section do
        transitions from: :identify_completed, to: :create_completed do
          guard do
            harm_scenarios.collect(&:valid_for_completion?).exclude?(false)
          end
        end
      end

      # Runs when a new harm scenario is added
      event :uncomplete_create_section do
        transitions from: :create_completed, to: :identify_completed do
          after do
            NORMAL_RISK_EVALUATE_STEPS.map(&:to_s).each do |evaluate_step|
              self.tasks_status[evaluate_step] = "not_started" # rubocop:disable Style/RedundantSelf
            end
          end
        end
      end

      event :submit do
        transitions from: :create_completed, to: :submitted
      end
    end

    def product
      @product ||= if associated_investigations.present? && associated_investigation_products.present?
                     associated_investigations.first.associated_investigation_products.first.product
                   elsif associated_products.present?
                     associated_products.first.product
                   end
    end

    def product_name
      if associated_investigations.present? && associated_investigation_products.present?
        associated_investigations.first.associated_investigation_products.first.product.name
      elsif associated_products.present?
        associated_products.first.product.name
      else
        "Unknown product"
      end
    end

    def user
      User.find(created_by_user_id) if created_by_user_id.present?
    end

  private

    def check_all_harm_scenarios
      harm_scenario_statuses = harm_scenarios.collect(&:valid_for_completion?)
      errors.add(:harm_scenarios, :invalid, invalid: harm_scenario_statuses.tally[false], count: harm_scenario_statuses.length) if harm_scenario_statuses.include?(false)
    end

    def multiple_harm_scenarios?
      harm_scenarios.length > 1
    end

    def multiple_harm_scenarios_with_identical_severity_levels?
      multiple_harm_scenarios? && harm_scenarios.map(&:severity).uniq.length <= 1
    end

    def clear_serious_risk_rebuttable_factors
      self.serious_risk_rebuttable_factors = nil unless less_than_serious_risk
    end

    def clear_overall_product_risk_plus_label
      self.overall_product_risk_plus_label = nil unless multiple_harm_scenarios?
    end

    def clear_overall_product_risk_methodology
      self.overall_product_risk_methodology = nil unless multiple_harm_scenarios_with_identical_severity_levels?
    end
  end
end
