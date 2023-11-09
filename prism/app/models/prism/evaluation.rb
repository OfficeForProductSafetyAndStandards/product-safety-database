module Prism
  class Evaluation < ApplicationRecord
    belongs_to :risk_assessment

    enum :level_of_uncertainty, {
      "low" => "low",
      "medium" => "medium",
      "high" => "high",
    }, prefix: true

    enum :number_of_products_expected_to_change, {
      "no_changes" => "no_changes",
      "increase" => "increase",
      "fall" => "fall",
      "unknown" => "unknown",
    }, prefix: true

    enum :comparable_risk_level, {
      "lower" => "lower",
      "similar" => "similar",
      "higher" => "higher",
      "unknown" => "unknown",
    }, prefix: true

    enum :significant_risk_differential, {
      "yes" => "yes",
      "no" => "no",
      "not_applicable" => "not_applicable",
    }, prefix: true

    enum :relevant_action_by_others, {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }, prefix: true

    enum :low_likelihood_high_severity, {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }, prefix: true

    enum :aimed_at_vulnerable_users, {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }, prefix: true

    enum :designed_to_provide_protective_function, {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }, prefix: true

    enum risk_tolerability: {
      "tolerable" => "tolerable",
      "intolerable" => "intolerable",
    }

    validates :level_of_uncertainty, inclusion: %w[low medium high], on: :add_level_of_uncertainty_and_sensitivity_analysis
    validates :sensitivity_analysis, inclusion: [true, false], on: :add_level_of_uncertainty_and_sensitivity_analysis
    validates :other_types_of_harm, array_intersection: { in: %w[psychological_harm damage_to_property harm_to_animals harm_to_the_environment] }, if: -> { other_types_of_harm.present? }, on: :consider_the_nature_of_the_risk
    validates :number_of_products_expected_to_change, inclusion: %w[no_changes increase fall unknown], on: :consider_the_nature_of_the_risk
    validates :uncertainty_level_implications_for_risk_management, inclusion: [true, false], on: :consider_the_nature_of_the_risk
    validates :comparable_risk_level, inclusion: %w[lower similar higher unknown], on: :consider_the_nature_of_the_risk
    validates :multiple_casualties, inclusion: [true, false], on: :consider_the_nature_of_the_risk
    validates :significant_risk_differential, inclusion: %w[yes no not_applicable], on: :consider_the_nature_of_the_risk
    validates :people_at_increased_risk, inclusion: [true, false], on: :consider_the_nature_of_the_risk
    validates :relevant_action_by_others, inclusion: %w[yes no unknown], on: :consider_the_nature_of_the_risk
    validates :factors_to_take_into_account, inclusion: [true, false], on: :consider_the_nature_of_the_risk
    validates :other_hazards, inclusion: [true, false], on: :consider_perception_and_tolerability_of_the_risk
    validates :low_likelihood_high_severity, inclusion: %w[yes no unknown], on: :consider_perception_and_tolerability_of_the_risk
    validates :risk_to_non_users, inclusion: [true, false], on: :consider_perception_and_tolerability_of_the_risk
    validates :aimed_at_vulnerable_users, inclusion: %w[yes no unknown], on: :consider_perception_and_tolerability_of_the_risk
    validates :designed_to_provide_protective_function, inclusion: %w[yes no unknown], on: :consider_perception_and_tolerability_of_the_risk
    validates :user_control_over_risk, inclusion: [true, false], on: :consider_perception_and_tolerability_of_the_risk
    validates :risk_tolerability, inclusion: %w[tolerable intolerable], on: :risk_evaluation_outcome

    before_save :clear_sensitivity_analysis_details

  private

    def clear_sensitivity_analysis_details
      self.sensitivity_analysis_details = nil unless sensitivity_analysis
    end
  end
end
