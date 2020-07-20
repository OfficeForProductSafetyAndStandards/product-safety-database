class AddRiskAssessmentToCase
  include Interactor

  delegate :investigation, :user, :assessed_on, :risk_level, :custom_risk_level,
    :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :product_ids,
    to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.risk_assessment = investigation.risk_assessments.create!(
      added_by_user: user,
      added_by_team: user.team,
      assessed_on: assessed_on,
      risk_level: risk_level,
      custom_risk_level: custom_risk_level,
      assessed_by_team_id: assessed_by_team_id,
      assessed_by_business_id: assessed_by_business_id,
      assessed_by_other: assessed_by_other,
      details: details,
      product_ids: product_ids
    )

  end


end
