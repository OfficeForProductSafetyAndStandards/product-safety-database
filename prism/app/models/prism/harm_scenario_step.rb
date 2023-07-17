module Prism
  class HarmScenarioStep < ApplicationRecord
    belongs_to :harm_scenario

    enum probability_evidence: {
      "sole_judgement_or_estimation" => "sole_judgement_or_estimation",
      "some_limited_empirical_evidence" => "some_limited_empirical_evidence",
      "strong_empirical_evidence" => "strong_empirical_evidence",
    }

    enum probability_type: {
      "decimal" => "decimal",
      "frequency" => "frequency",
    }

    validates :description, presence: true
    validates :probability_type, presence: true, inclusion: %w[decimal frequency]
    validates :probability_decimal, presence: true, numericality: true, if: -> { probability_type == "decimal" }
    validates :probability_frequency, presence: true, numericality: { only_integer: true }, if: -> { probability_type == "frequency" }
    validates :probability_evidence, presence: true, inclusion: %w[sole_judgement_or_estimation some_limited_empirical_evidence strong_empirical_evidence]

    before_save :clear_probability

  private

    def clear_probability
      self.probability_decimal = nil if probability_type == "frequency"
      self.probability_frequency = nil if probability_type == "decimal"
    end
  end
end
