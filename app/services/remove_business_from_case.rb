class RemoveBusinessFromCase
  include Interactor

  context :reason, :investigation, :business, to: :context

  def call
    context.fail!(error: "No business supplied") unless product.is_a?(Business)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.businesses.delete(business)

    create_audit_activity_for_business_removed

    send_notification_email
  end

private

  def create_audit_activity_for_business_removed
    AuditActivity::Business::Destroy.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: "Removed: #{business.trading_name}",
      business: business
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Business was removed from the #{investigation.case_type} by #{context.activity.source.show(recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
