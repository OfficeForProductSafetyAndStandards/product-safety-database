class ChangeNotificationReferenceNumber
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :reference_number, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No reference number supplied") unless reference_number.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.assign_attributes(complainant_reference: reference_number)
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_reference_number_changed
    end
  end

private

  def create_audit_activity_for_reference_number_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateReferenceNumber
  end
end
