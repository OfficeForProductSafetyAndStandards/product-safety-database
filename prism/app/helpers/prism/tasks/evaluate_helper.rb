module Prism
  module Tasks::EvaluateHelper
    def overall_product_risk_level
      return unless @prism_risk_assessment && (@prism_risk_assessment.serious_risk? || @harm_scenarios)

      if @prism_risk_assessment.serious_risk?
        # The overall product risk level is always serious by definition
        Prism::RiskMatrixService.highest_risk_level(risk_levels: %w[serious])
      elsif @harm_scenarios.length == 1
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

    def risk_to_non_users
      return unless @harm_scenarios

      I18n.t("prism.evaluation.risk_to_non_users.#{@harm_scenarios.map(&:unintended_risks_for).flatten.length.positive?}")
    end

    def country_from_code(code)
      country = ::Country.all.find { |c| c[1] == code }
      (country && country[0]) || code
    end

    def counterfeit(authenticity)
      I18n.t("prism.evaluation.counterfeit.#{authenticity}") if authenticity.present?
    end

    def product_safety_legislation_standards_list(safety_legislation_standards)
      "<ul class=\"govuk-list govuk-list--bullet\"><li>#{safety_legislation_standards.join('</li><li>')}</li></ul>".html_safe
    end

    def harm_scenario_hazard_type(hazard_type)
      I18n.t("prism.harm_scenarios.hazard_types.#{hazard_type}")
    end

    def harm_scenario_product_aimed_at(product_aimed_at, product_aimed_at_description)
      product_aimed_at == "general_population" ? I18n.t("prism.harm_scenarios.product_aimed_at.general_population") : product_aimed_at_description
    end

    def harm_scenario_unintended_risks_for(unintended_risks_for)
      unintended_risks_for.present? ? unintended_risks_for.map { |urf| I18n.t("prism.evaluation.unintended_risks_for.#{urf}") }.join(", ") : I18n.t("prism.evaluation.unintended_risks_for.not_applicable")
    end

    def harm_scenario_probability_evidence(probability_evidence)
      I18n.t("prism.evaluation.probability_evidence.#{probability_evidence}")
    end

    def harm_scenario_evidence_file(harm_scenario_step_evidence)
      harm_scenario_step_evidence.present? ? (render partial: "attachment", locals: { file: harm_scenario_step_evidence.evidence_file }) : ""
    end

    def harm_scenario_severity_level_and_multiple_casualties(severity_level, multiple_casualties)
      "<ul class=\"govuk-list govuk-list--bullet\"><li>#{I18n.t("prism.harm_scenarios.severity.#{severity_level}")}</li><li>#{I18n.t("prism.evaluation.multiple_casualties_verbose.#{multiple_casualties}")}</li></ul>".html_safe
    end

    def harm_scenario_severity_level(severity_level)
      I18n.t("prism.harm_scenarios.severity.#{severity_level}")
    end

    def harm_scenario_multiple_casualties(multiple_casualties)
      I18n.t("prism.evaluation.multiple_casualties_verbose.#{multiple_casualties}")
    end

    def harm_scenario_overall_probability_of_harm(harm_scenario)
      Prism::ProbabilityService.overall_probability_of_harm(harm_scenario:).probability
    end

    def sensitivity_analysis_with_details(sensitivity_analysis, sensitivity_analysis_details)
      sensitivity_analysis_details.present? ? "#{I18n.t('prism.evaluation.yes_no.true')}: #{sensitivity_analysis_details}" : I18n.t("prism.evaluation.yes_no.#{sensitivity_analysis}")
    end

    def other_types_of_harm(other_types_of_harm)
      other_types_of_harm.present? ? other_types_of_harm.map { |oth| I18n.t("prism.evaluation.other_types_of_harm.#{oth}") }.join(", ") : I18n.t("prism.evaluation.other_types_of_harm.not_applicable")
    end

    def people_at_increased_risk(people_at_increased_risk, people_at_increased_risk_details)
      people_at_increased_risk_details.present? ? "#{I18n.t('prism.evaluation.yes_no.true')}: #{people_at_increased_risk_details}" : I18n.t("prism.evaluation.yes_no.#{people_at_increased_risk}")
    end

    def factors_to_take_into_account(factors_to_take_into_account, factors_to_take_into_account_details)
      factors_to_take_into_account_details.present? ? "#{I18n.t('prism.evaluation.yes_no.true')}: #{factors_to_take_into_account_details}" : I18n.t("prism.evaluation.yes_no.#{factors_to_take_into_account}")
    end

    def other_risk_perception_matters(other_risk_perception_matters)
      other_risk_perception_matters.presence || I18n.t("prism.evaluation.other_risk_perception_matters.no_other_matters")
    end

    def evaluation_translate_simple(key, value)
      I18n.t("prism.evaluation.#{key}.#{value}")
    end
  end
end
