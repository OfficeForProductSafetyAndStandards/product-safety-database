class ChangeSafetyAndComplianceData
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :hazard_type, :hazard_description, :non_compliant_reason, :reported_reason, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_attributes
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_safety_and_compliance_change
    end

    context.changes_made = true

    send_notification_email(investigation, user)
  end

private

  def assign_attributes
    if reported_reason == :safe_and_compliant
      investigation.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: nil, reported_reason: reported_reason)
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

  def send_notification_email(investigation, user)
    email_recipients_for_team_with_access(investigation, user).each do |entity|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        entity.email,
        "#{user.name} (#{user.team.name}) edited safety and compliance data on the #{investigation.case_type}.",
        "Safety and compliance data edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
