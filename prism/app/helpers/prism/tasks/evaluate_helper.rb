module Prism
  module Tasks::EvaluateHelper
    def level_of_uncertainty(prism_risk_assessment = nil)
      return unless @prism_risk_assessment || prism_risk_assessment

      record = @prism_risk_assessment || prism_risk_assessment

      return "Unknown" if record.level_of_uncertainty.nil?

      I18n.t("prism.risk_assessment.level_of_uncertainty.#{record.level_of_uncertainty}")
    end
  end
end
