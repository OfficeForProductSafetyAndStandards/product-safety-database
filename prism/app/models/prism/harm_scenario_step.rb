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
  end
end
