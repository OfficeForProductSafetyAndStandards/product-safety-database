module Prism
  module Tasks::EvaluateHelper
    def overall_product_risk_level
      return unless @prism_risk_assessment && @harm_scenarios && @items_in_use

      if @harm_scenarios.length == 1
        overall_risk_level(@harm_scenarios.first)
      elsif @prism_risk_assessment.overall_product_risk_methodology == "combined"
        combined_risk_level(@harm_scenarios, @items_in_use)
      else
        highest_risk_level(@harm_scenarios)
      end
    end

    def question_hint_panel(content)
      <<~HTML
        <div class="opss-panel">
          <p class="govuk-body">As recorded in the assessment</p>
          <p class="govuk-body-l">#{content}</p>
        </div>
      HTML
    end

    def estimated_products_in_use
      return unless @items_in_use

      I18n.t("prism.evaluation.estimated_products_in_use", items_in_use: ActiveSupport::NumberHelper.number_to_delimited(@items_in_use), count: @items_in_use || 0)
    end

    def level_of_uncertainty
      return unless @evaluation

      I18n.t("prism.evaluation.level_of_uncertainty.#{@evaluation.level_of_uncertainty}")
    end

    def multiple_casualties
      return unless @harm_scenarios

      I18n.t("prism.evaluation.multiple_casualties.#{@harm_scenarios.map(&:multiple_casualties).include?(true)}")
    end

    def people_at_increased_risk
      return unless @harm_scenarios

      @harm_scenarios.map(&:product_aimed_at_description).reject(&:blank?).join(", ").presence || I18n.t("prism.evaluation.people_at_increased_risk.false")
    end
  end
end
