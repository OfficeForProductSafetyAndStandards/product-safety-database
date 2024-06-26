class UpdateRiskAssessment
  include Interactor
  include EntitiesToNotify

  delegate :risk_assessment, :user, :assessed_on, :risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :investigation_product_ids, :risk_assessment_file, to: :context

  delegate :investigation, to: :risk_assessment

  def call
    context.fail!(error: "No risk assessment supplied") unless risk_assessment.is_a?(RiskAssessment)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    @previous_investigation_product_ids = risk_assessment.investigation_product_ids
    @previous_attachment_filename = risk_assessment.risk_assessment_file.filename

    ActiveRecord::Base.transaction do
      risk_assessment.assign_attributes(
        assessed_on:,
        risk_level:,
        assessed_by_team_id: assessed_by_team_id.presence,
        assessed_by_business_id: assessed_by_business_id.presence,
        assessed_by_other: assessed_by_other.presence,
        details:,
        investigation_product_ids:
      )

      if risk_assessment_file
        risk_assessment.risk_assessment_file.detach
        risk_assessment.risk_assessment_file.attach(risk_assessment_file)
      end

      break if no_changes?

      risk_assessment.save!

      create_audit_activity
      send_notification_email
    end
  end

private

  def no_changes?
    !risk_assessment.changed? && !risk_assessment_file && investigation_products_unchanged?
  end

  def investigation_products_unchanged?
    @previous_investigation_product_ids.sort == investigation_product_ids.map(&:to_i).sort
  end

  def create_audit_activity
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.create!(
      added_by_user: user,
      investigation:,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def audit_activity_metadata
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.build_metadata(
      risk_assessment:,
      previous_investigation_product_ids: @previous_investigation_product_ids,
      attachment_changed: risk_assessment_file.present?,
      previous_attachment_filename: @previous_attachment_filename
    )
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user.decorate.display_name(viewer: recipient)} edited a risk assessment on the notification.",
        "Risk assessment edited for notification"
      ).deliver_later
    end
  end
end
