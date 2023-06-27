module Prism
  module Form
    class FullRiskAssessmentRequired
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :full_risk_assessment_required, :boolean

      validates :full_risk_assessment_required, inclusion: [true, false]
    end
  end
end
