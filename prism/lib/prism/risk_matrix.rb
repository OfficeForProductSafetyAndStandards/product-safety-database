module Prism
  class RiskMatrix
    RISK_MATRIX = {
      more_than_or_equal_to_1_in_2: {
        level_1: "high",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_or_equal_to_1_in_10: {
        level_1: "medium",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_or_equal_to_1_in_100: {
        level_1: "medium",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_or_equal_to_1_in_1000: {
        level_1: "low",
        level_2: "high",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_or_equal_to_1_in_10000: {
        level_1: "low",
        level_2: "medium",
        level_3: "high",
        level_4: "serious",
      },
      more_than_or_equal_to_1_in_100000: {
        level_1: "low",
        level_2: "low",
        level_3: "medium",
        level_4: "high",
      },
      more_than_or_equal_to_1_in_1000000: {
        level_1: "low",
        level_2: "low",
        level_3: "low",
        level_4: "medium",
      },
      less_than_1_in_1000000: {
        level_1: "low",
        level_2: "low",
        level_3: "low",
        level_4: "low",
      },
    }.freeze

    def self.risk_level(probability_frequency:, severity_level:)
      raise "Severity level must be one of `:level_1`, `:level_2`, `:level_3` or `:level_4`" unless %i[level_1 level_2 level_3 level_4].include?(severity_level)

      RISK_MATRIX[probability_frequency_band(probability_frequency:)][severity_level]
    end

    private_class_method def self.probability_frequency_band(probability_frequency:)
      # `probability_frequency` is the `n` in "1 in n".
      # Lower numbers indicate a greater probability.
      # The bands below overlap but the first case is returned.
      case probability_frequency
      when ..2
        :more_than_or_equal_to_1_in_2
      when 2..10
        :more_than_or_equal_to_1_in_10
      when 10..100
        :more_than_or_equal_to_1_in_100
      when 100..1000
        :more_than_or_equal_to_1_in_1000
      when 1000..10_000
        :more_than_or_equal_to_1_in_10000
      when 10_000..100_000
        :more_than_or_equal_to_1_in_100000
      when 100_000..1_000_000
        :more_than_or_equal_to_1_in_1000000
      else
        :less_than_1_in_1000000
      end
    end
  end
end
