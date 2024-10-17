module Prism
  class ApiController < ApplicationController
    skip_before_action :authenticate_user!

    def overall_probability_of_harm_and_risk_level
      # Process probabilities by handling `nil`, splitting into an array and casting to decimals
      probabilities_decimal = params[:probabilities_decimal].to_s.split(",").map(&:to_f)
      probabilities_frequency = params[:probabilities_frequency].to_s.split(",").map(&:to_f)
      severity_level = params[:severity_level].to_sym

      overall_probability_of_harm = Prism::ProbabilityService.overall_probability_of_harm(harm_scenario: nil, probabilities_decimal:, probabilities_frequency:)
      overall_risk_level = Prism::RiskMatrixService.risk_level(probability_frequency: overall_probability_of_harm.probability, severity_level:)

      render json:
        {
          result:
            {
              probability: overall_probability_of_harm.probability,
              probability_human: overall_probability_of_harm.probability_human,
              risk_level: overall_risk_level.risk_level,
              risk_level_tag_html: overall_risk_level.risk_level_tag_html,
            },
          status: 200
        }
    end
  end
end
