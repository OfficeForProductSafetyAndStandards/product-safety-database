class UpdateRiskAssessment
  include Interactor

  delegate :risk_assessment, :user, :assessed_on, :risk_level, :custom_risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :product_ids, :risk_assessment_file, to: :context

  def call
    ActiveRecord::Base.transaction do
      risk_assessment.update!({
        assessed_on: assessed_on,
        risk_level: risk_level,
        custom_risk_level: custom_risk_level.presence,
        assessed_by_team_id: assessed_by_team_id.presence,
        assessed_by_business_id: assessed_by_business_id.presence,
        assessed_by_other: assessed_by_other.presence,
        details: details,
        product_ids: product_ids
      })
    end
  end
end
