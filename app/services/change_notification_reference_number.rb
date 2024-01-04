class ChangeNotificationReferenceNumber
  include Interactor
  include EntitiesToNotify

  delegate :notification, :reference_number, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No reference number supplied") unless reference_number.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    notification.assign_attributes(complainant_reference: reference_number)
    return if notification.changes.none?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_reference_number_changed
    end
  end

private

  def create_audit_activity_for_reference_number_changed
    metadata = AuditActivity::Investigation::UpdateReferenceNumber.build_metadata(notification)
    AuditActivity::Investigation::UpdateReferenceNumber.create!(
      added_by_user: user,
      investigation: notification,
      title: nil,
      body: nil,
      metadata:
    )
  end
end
