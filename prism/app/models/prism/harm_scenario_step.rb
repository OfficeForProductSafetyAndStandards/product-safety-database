module Prism
  class HarmScenarioStep < ApplicationRecord
    belongs_to :harm_scenario
    has_one :harm_scenario_step_evidence

    accepts_nested_attributes_for :harm_scenario_step_evidence, reject_if: :all_blank

    default_scope { order(created_at: :asc) }

    enum probability_evidence: {
      "sole_judgement_or_estimation" => "sole_judgement_or_estimation",
      "some_limited_empirical_evidence" => "some_limited_empirical_evidence",
      "strong_empirical_evidence" => "strong_empirical_evidence",
    }

    enum probability_type: {
      "decimal" => "decimal",
      "frequency" => "frequency",
    }

    attribute :probability_evidence_description_limited, :string
    attribute :probability_evidence_description_strong, :string

    validates :description, presence: true, on: :add_steps_to_harm
    validates :probability_type, inclusion: %w[decimal frequency], on: :estimate_probability_of_harm
    validates :probability_decimal, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1 }, if: -> { probability_type == "decimal" }, on: :estimate_probability_of_harm
    validates :probability_frequency, presence: true, numericality: { greater_than: 0, only_integer: true }, if: -> { probability_type == "frequency" }, on: :estimate_probability_of_harm
    validates :probability_evidence, inclusion: %w[sole_judgement_or_estimation some_limited_empirical_evidence strong_empirical_evidence], on: :estimate_probability_of_harm
    validates :probability_evidence_description_limited, presence: true, if: -> { probability_evidence == "some_limited_empirical_evidence" }, on: :estimate_probability_of_harm
    validates :probability_evidence_description_strong, presence: true, if: -> { probability_evidence == "strong_empirical_evidence" }, on: :estimate_probability_of_harm
    validates :harm_scenario_step_evidence, presence: true, if: -> { %w[some_limited_empirical_evidence strong_empirical_evidence].include?(probability_evidence) }, on: :estimate_probability_of_harm

    after_find :set_probability_evidence_description_virtual_attributes
    before_validation :set_probability_evidence_description
    before_save :clear_probability
    before_save :clear_harm_scenario_step_evidence

    def probability_of_harm
      return unless probability_type

      { type: probability_type, probability: probability_frequency || probability_decimal }
    end

  private

    def set_probability_evidence_description_virtual_attributes
      return unless has_attribute?(:probability_evidence)

      case probability_evidence
      when "some_limited_empirical_evidence"
        self.probability_evidence_description_limited = probability_evidence_description
      when "strong_empirical_evidence"
        self.probability_evidence_description_strong = probability_evidence_description
      end
    end

    def set_probability_evidence_description
      self.probability_evidence_description = case probability_evidence
                                              when "sole_judgement_or_estimation"
                                                nil
                                              when "some_limited_empirical_evidence"
                                                probability_evidence_description_limited
                                              when "strong_empirical_evidence"
                                                probability_evidence_description_strong
                                              end
    end

    def clear_probability
      self.probability_decimal = nil if probability_type == "frequency"
      self.probability_frequency = nil if probability_type == "decimal"
    end

    def clear_harm_scenario_step_evidence
      harm_scenario_step_evidence.destroy! if probability_evidence == "sole_judgement_or_estimation" && harm_scenario_step_evidence.present?
    end
  end
end
