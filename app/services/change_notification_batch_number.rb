class ChangeNotificationBatchNumber
  include Interactor
  include EntitiesToNotify

  delegate :notification_product, :batch_number, :user, to: :context

  def call
    context.fail!(error: "No investigation product supplied") unless notification_product.is_a?(InvestigationProduct)
    context.fail!(error: "No batch number supplied") unless batch_number.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    notification_product.assign_attributes(batch_number:)
    return if notification_product.changes.none?

    ActiveRecord::Base.transaction do
      notification_product.save!
      create_audit_activity_for_batch_number_changed
    end

    send_notification_email unless context.silent
  end

private

  def create_audit_activity_for_batch_number_changed
    metadata = activity_class.build_metadata(notification_product)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateCaseSpecificProductInformationDecorator
  end

  def send_notification_email
    email_recipients_for_case_owner(notification).each do |recipient|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Notification batch number updated"
      ).deliver_later
    end
  end

  def investigation
    notification_product.investigation
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Notification batch number was updated by #{user_name}."
  end
end
