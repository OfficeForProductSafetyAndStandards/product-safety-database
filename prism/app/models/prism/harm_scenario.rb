module Prism
  class HarmScenario < ApplicationRecord
    belongs_to :risk_assessment
    has_many :harm_scenario_steps, autosave: true

    enum hazard_type: {
      "mechanical" => "mechanical",
      "size_and_shape" => "size_and_shape",
      "electrical" => "electrical",
      "fire_and_explosion" => "fire_and_explosion",
      "thermal" => "thermal",
      "ergonomic" => "ergonomic",
      "noise_and_vibration" => "noise_and_vibration",
      "microbiological" => "microbiological",
      "chemical" => "chemical",
      "lack_of_protection" => "lack_of_protection",
      "other" => "other",
    }

    enum severity: {
      "level_1" => "level_1",
      "level_2" => "level_2",
      "level_3" => "level_3",
      "level_4" => "level_4",
    }

    enum level_of_uncertainty: {
      "low" => "low",
      "medium" => "medium",
      "high" => "high",
    }

    validates :hazard_type, presence: true, inclusion: %w[mechanical size_and_shape electrical fire_and_explosion thermal ergonomic noise_and_vibration microbiological chemical lack_of_protection other], on: :choose_hazard_type
    validates :other_hazard_type, presence: true, if: -> { hazard_type == "other" }, on: :choose_hazard_type
    validates :description, presence: true, on: :choose_hazard_type

    before_save :clear_other_hazard_type

  private

    def clear_other_hazard_type
      self.other_hazard_type = nil unless hazard_type == "other"
    end
  end
end
