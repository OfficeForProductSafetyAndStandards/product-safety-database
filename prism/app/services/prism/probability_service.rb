module Prism
  class ProbabilityService
    def self.overall_probability_of_harm(harm_scenario:, probabilities_decimal: nil, probabilities_frequency: nil)
      probabilities = if harm_scenario.present?
                        # Get the probability of harm for all harm scenario steps
                        probabilities = []
                        steps = harm_scenario.harm_scenario_steps.select(:probability_type, :probability_decimal, :probability_frequency)

                        # For any probability expressed as a frequency, transform it into a decimal
                        steps.each do |step|
                          probabilities << if step.probability_type == "frequency"
                                             step.probability_frequency.zero? ? 0 : (1.0 / step.probability_frequency)
                                           else
                                             step.probability_decimal
                                           end
                        end

                        probabilities
                      else
                        # Use the provided probabilities
                        probabilities_frequency.map { |probability| probability.zero? ? 0 : 1.0 / probability } + probabilities_decimal
                      end

      probabilities = probabilities.reject { |probability| probability.blank? || probability.zero? }

      # If there are no harm scenarios or they all had a probability of zero, return
      if probabilities.blank?
        return OpenStruct.new(
          probability: nil,
          probability_decimal: nil,
          probability_human: "N/A",
        )
      end

      # Multiply all the probabilities together, transform into a frequency and round
      # since we don't want any decimal places
      probability_decimal = probabilities.reduce(:*)
      probability = (1.0 / probability_decimal).round

      # If probability is zero, return
      if probability.zero?
        return OpenStruct.new(
          probability: nil,
          probability_decimal: nil,
          probability_human: "N/A",
        )
      end

      OpenStruct.new(
        probability:,
        probability_decimal:,
        probability_human: "1 in #{ActiveSupport::NumberHelper.number_to_delimited(probability)}",
      )
    end

    def self.combined_probability_of_harm(harm_scenarios:)
      probabilities = harm_scenarios.map { |harm_scenario| overall_probability_of_harm(harm_scenario:) }
      probability_decimal = probabilities.map(&:probability_decimal).sum

      if probability_decimal.blank?
        return OpenStruct.new(
          probability: nil,
          probability_decimal: nil,
        )
      end

      probability = (1.0 / probability_decimal).round

      OpenStruct.new(
        probability:,
        probability_decimal:,
      )
    end
  end
end
