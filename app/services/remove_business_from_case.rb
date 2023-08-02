class RemoveBusinessFromCase
  include Interactor
  include EntitiesToNotify

  delegate :user, :reason, :investigation, :business, to: :context

  def call
    context.fail!(error: "No business supplied") unless business.is_a?(Business)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    if attached_to_supporting_information?
      context.fail!(error: :business_is_attached_to_supporting_information)
    end

    investigation.businesses.delete(business)
    investigation.__elasticsearch__.update_document

    send_notification_email(create_audit_activity_for_business_removed)
  end

private

  def create_audit_activity_for_business_removed
    AuditActivity::Business::Destroy.create!(
      added_by_user: user,
      investigation:,
      business:,
      metadata: AuditActivity::Business::Destroy.build_metadata(business, reason)
    )
  end

  def send_notification_email(_activity)
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Business was removed from the case by #{user.decorate.display_name(viewer: recipient)}.",
        "Case updated"
      ).deliver_later
    end
  end

  def attached_to_supporting_information?
    investigation.corrective_actions.where(business:).exists? || investigation.risk_assessments.where(assessed_by_business: business).exists?
  end
end
