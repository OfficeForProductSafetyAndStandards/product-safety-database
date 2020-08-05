class AddRiskAssessmentToCase
  include Interactor

  delegate :investigation, :user, :assessed_on, :risk_level, :custom_risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :product_ids, :risk_assessment_file, :risk_assessment, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      context.risk_assessment = investigation.risk_assessments.create!(
        added_by_user: user,
        added_by_team: user.team,
        assessed_on: assessed_on,
        risk_level: risk_level,
        custom_risk_level: custom_risk_level.presence,
        assessed_by_team_id: assessed_by_team_id.presence,
        assessed_by_business_id: assessed_by_business_id.presence,
        assessed_by_other: assessed_by_other.presence,
        details: details,
        product_ids: product_ids
      )

      context.risk_assessment.risk_assessment_file.attach(risk_assessment_file)
      create_audit_activity
    end
    send_notification_email
  end

private

  def create_audit_activity
    AuditActivity::RiskAssessment::RiskAssessmentAdded.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def audit_activity_metadata
    AuditActivity::RiskAssessment::RiskAssessmentAdded.build_metadata(risk_assessment)
  end

  def send_notification_email
    entities_to_notify.each do |recipient|
      email = recipient.is_a?(Team) ? recipient.team_recipient_email : recipient.email

      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        email,
        "Risk assessment was added to the #{investigation.case_type} by #{user.decorate.display_name(recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end

  def entities_to_notify
    if investigation.owner_user && investigation.owner_user == user
      []
    elsif investigation.owner_user
      [investigation.owner_user]
    elsif investigation.owner_team.team_recipient_email.present?
      [investigation.owner_team]
    else
      investigation.owner_team.users.active
    end
  end
end
