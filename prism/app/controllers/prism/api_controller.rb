module Prism
  class ApiController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :authorize_user

    def overall_probability_of_harm
      return render json: { error: "At least one of probabilities_decimal and probabilities_frequency must be provided", status: 400 } unless params[:probabilities_decimal].present? || params[:probabilities_frequency].present?

      # Process probabilities by handling `nil`, splitting into an array and casting to decimals
      probabilities_decimal = params[:probabilities_decimal].to_s.split(",").map(&:to_f)
      probabilities_frequency = params[:probabilities_frequency].to_s.split(",").map(&:to_f)

      overall_probability_of_harm = Prism::ProbabilityService.overall_probability_of_harm(harm_scenario: nil, probabilities_decimal:, probabilities_frequency:)

      render json: { result: { probability: overall_probability_of_harm.probability, probability_human: overall_probability_of_harm.probability_human }, status: 200 }
    end
  end
end
