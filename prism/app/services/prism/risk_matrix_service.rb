module Prism
  class RiskMatrixService
    RISK_MATRIX = {
      more_than_1_in_2: {
        level_1: "high",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_1_in_10: {
        level_1: "medium",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_1_in_100: {
        level_1: "medium",
        level_2: "serious",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_1_in_1000: {
        level_1: "low",
        level_2: "high",
        level_3: "serious",
        level_4: "serious",
      },
      more_than_1_in_10000: {
        level_1: "low",
        level_2: "medium",
        level_3: "high",
        level_4: "serious",
      },
      more_than_1_in_100000: {
        level_1: "low",
        level_2: "low",
        level_3: "medium",
        level_4: "high",
      },
      more_than_1_in_1000000: {
        level_1: "low",
        level_2: "low",
        level_3: "low",
        level_4: "medium",
      },
      less_than_or_equal_to_1_in_1000000: {
        level_1: "low",
        level_2: "low",
        level_3: "low",
        level_4: "low",
      },
    }.freeze

    COMBINED_RISK_MATRIX = {
      less_than_or_equal_to_100000: {
        low: "low",
        medium: "medium",
        high: "high",
        serious: "serious",
      },
      from_100001_to_500000: {
        low: "medium",
        medium: "high",
        high: "high",
        serious: "serious",
      },
      from_500001_to_1000000: {
        low: "medium",
        medium: "high",
        high: "serious",
        serious: "serious",
      },
      more_than_1000000: {
        low: "high",
        medium: "serious",
        high: "serious",
        serious: "serious",
      },
    }.freeze

    def self.risk_level(probability_frequency:, severity_level:)
      risk_level = RISK_MATRIX[probability_frequency_band(probability_frequency:)]&.[](severity_level)

      OpenStruct.new(
        risk_level:,
        risk_level_tag_html: risk_level_tag(risk_level:)
      )
    end

    def self.highest_risk_level(risk_levels:)
      highest_risk_level = case risk_levels
                           in [*, "serious", *]
                             "serious"
                           in [*, "high", *]
                             "high"
                           in [*, "medium", *]
                             "medium"
                           in [*, "low", *]
                             "low"
                           else
                             "unknown"
                           end

      OpenStruct.new(
        risk_level: highest_risk_level,
        risk_level_tag_html: risk_level_tag(risk_level: highest_risk_level)
      )
    end

    def self.combined_risk_level(risk_level:, items_in_use:)
      combined_risk_level = items_in_use.present? ? COMBINED_RISK_MATRIX[items_in_use_band(items_in_use:)]&.[](risk_level.to_sym) : risk_level

      OpenStruct.new(
        risk_level: combined_risk_level,
        risk_level_tag_html: risk_level_tag(risk_level: combined_risk_level)
      )
    end

    private_class_method def self.probability_frequency_band(probability_frequency:)
      # `probability_frequency` is the `n` in "1 in n".
      # Lower numbers indicate a greater probability.
      return unless probability_frequency.is_a?(Integer)

      case probability_frequency
      when ..1
        :more_than_1_in_2
      when 2..9
        :more_than_1_in_10
      when 10..99
        :more_than_1_in_100
      when 100..999
        :more_than_1_in_1000
      when 1000..9_999
        :more_than_1_in_10000
      when 10_000..99_999
        :more_than_1_in_100000
      when 100_000..999_999
        :more_than_1_in_1000000
      else
        :less_than_or_equal_to_1_in_1000000
      end
    end

    private_class_method def self.items_in_use_band(items_in_use:)
      return unless items_in_use.is_a?(Integer)

      case items_in_use
      when ..100_000
        :less_than_or_equal_to_100000
      when 100_001..500_000
        :from_100001_to_500000
      when 500_001..1_000_000
        :from_500001_to_1000000
      else
        :more_than_1000000
      end
    end

    private_class_method def self.risk_level_tag(risk_level:)
      component = case risk_level
                  when "low"
                    GovukComponent::TagComponent.new(text: "Low risk", colour: "green")
                  when "medium"
                    GovukComponent::TagComponent.new(text: "Medium risk", colour: "yellow")
                  when "high"
                    GovukComponent::TagComponent.new(text: "High risk", colour: "orange")
                  when "serious"
                    GovukComponent::TagComponent.new(text: "Serious risk", colour: "red")
                  else
                    GovukComponent::TagComponent.new(text: "Unknown risk", colour: "grey")
                  end
      component.render_in(ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil))
    end
  end
end
