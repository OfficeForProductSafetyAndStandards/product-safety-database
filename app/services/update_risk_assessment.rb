class UpdateRiskAssessment
  include Interactor
  include EntitiesToNotify

  delegate :risk_assessment, :user, :assessed_on, :risk_level, :custom_risk_level,
           :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details, :product_ids, :risk_assessment_file, to: :context

  delegate :investigation, to: :risk_assessment

  def call
    context.fail!(error: "No risk assessment supplied") unless risk_assessment.is_a?(RiskAssessment)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    @previous_product_ids = risk_assessment.product_ids
    @previous_attachment_filename = risk_assessment.risk_assessment_file.filename

    ActiveRecord::Base.transaction do
      risk_assessment.assign_attributes(
        assessed_on: assessed_on,
        risk_level: risk_level,
        custom_risk_level: custom_risk_level.presence,
        assessed_by_team_id: assessed_by_team_id.presence,
        assessed_by_business_id: assessed_by_business_id.presence,
        assessed_by_other: assessed_by_other.presence,
        details: details,
        product_ids: product_ids
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
    !risk_assessment.changed? && !risk_assessment_file
  end

  def create_audit_activity
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.create!(
      source: user_source,
      investigation: investigation,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def user_source
    @user_source ||= UserSource.new(user: user)
  end

  def audit_activity_metadata
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.build_metadata(
      risk_assessment: risk_assessment,
      previous_product_ids: @previous_product_ids,
      attachment_changed: risk_assessment_file.present?,
      previous_attachment_filename: @previous_attachment_filename
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user_source.show(recipient)} edited a risk assessment on the #{investigation.case_type}.",
        "Risk assessment edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
