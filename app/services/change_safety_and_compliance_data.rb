class ChangeSafetyAndComplianceData
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :hazard_type, :hazard_description, :non_compliant_reason, :reported_reason, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    assign_attributes
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_safety_and_compliance_change
    end

    # send_notification_email
  end

private

  def assign_attributes
    if reported_reason == :safe_and_compliant
      investigation.assign_attributes(hazard_description: nil, hazard_type:nil, non_compliant_reason: nil, reported_reason: reported_reason)
    end

    if reported_reason == :unsafe_and_non_compliant
      investigation.assign_attributes(hazard_description: hazard_description, hazard_type: hazard_type, non_compliant_reason: non_compliant_reason, reported_reason: reported_reason)
    end

    if reported_reason == :unsafe
      investigation.assign_attributes(hazard_description: hazard_description, hazard_type: hazard_type, non_compliant_reason: nil, reported_reason: reported_reason)
    end

    if reported_reason == :non_compliant
      investigation.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: non_compliant_reason, reported_reason: reported_reason)
    end
  end

  def create_audit_activity_for_safety_and_compliance_change
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: user_source,
      investigation: investigation,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeSafetyAndComplianceData
  end
  
  def user_source
    @user_source ||= UserSource.new(user: user)
  end
  #
  # def assign_risk_validation_attributes
  #   if is_risk_validated
  #     investigation.assign_attributes(risk_validated_at: risk_validated_at, risk_validated_by: risk_validated_by)
  #     context.change_action = I18n.t("change_risk_validation.validated")
  #   else
  #     investigation.assign_attributes(risk_validated_at: nil, risk_validated_by: nil)
  #     context.change_action = I18n.t("change_risk_validation.validation_removed")
  #   end
  # end
  #
  # def send_notification_email
  #   email_recipients_for_team_with_access(investigation, user).each do |entity|
  #     email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
  #     NotifyMailer.risk_validation_updated(
  #       email: email,
  #       updater: user,
  #       name: entity.name,
  #       investigation: investigation,
  #       action: change_action.to_s,
  #     ).deliver_later
  #   end
  # end
end
