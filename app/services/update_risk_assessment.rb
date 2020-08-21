class UpdateRiskAssessment
  include Interactor

  delegate :risk_assessment, :user, :assessed_on, :risk_level, :custom_risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :product_ids, :risk_assessment_file, to: :context

  def call
    @previous_product_ids = risk_assessment.product_ids
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
      create_audit_activity
    end
  end

private

  def create_audit_activity
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.create!(
      source: UserSource.new(user: user),
      investigation: risk_assessment.investigation,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def audit_activity_metadata
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.build_metadata(
      risk_assessment: risk_assessment,
      previous_product_ids: @previous_product_ids
    )
  end
end
