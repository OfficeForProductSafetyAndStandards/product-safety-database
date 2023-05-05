class AddRiskAssessmentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :assessed_on, :risk_level, :custom_risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :investigation_product_ids, :risk_assessment_file, :risk_assessment, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      context.risk_assessment = investigation.risk_assessments.create!(
        added_by_user: user,
        added_by_team: user.team,
        assessed_on:,
        risk_level:,
        custom_risk_level: custom_risk_level.presence,
        assessed_by_team_id: assessed_by_team_id.presence,
        assessed_by_business_id: assessed_by_business_id.presence,
        assessed_by_other: assessed_by_other.presence,
        details:,
        investigation_product_ids:
      )

      context.risk_assessment.risk_assessment_file.attach(risk_assessment_file)
      create_audit_activity
    end
    send_notification_email
  end

private

  def create_audit_activity
    AuditActivity::RiskAssessment::RiskAssessmentAdded.create!(
      added_by_user: user,
      investigation:,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def audit_activity_metadata
    AuditActivity::RiskAssessment::RiskAssessmentAdded.build_metadata(risk_assessment)
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Risk assessment was added to the case by #{user.decorate.display_name(viewer: recipient)}.",
        "Case updated"
      ).deliver_later
    end
  end
end
