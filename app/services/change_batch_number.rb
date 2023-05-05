class ChangeBatchNumber
  include Interactor
  include EntitiesToNotify

  delegate :investigation_product, :batch_number, :user, to: :context

  def call
    context.fail!(error: "No investigation product supplied") unless investigation_product.is_a?(InvestigationProduct)
    context.fail!(error: "No batch number supplied") unless batch_number.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation_product.assign_attributes(batch_number:)
    return if investigation_product.changes.none?

    ActiveRecord::Base.transaction do
      investigation_product.save!
      create_audit_activity_for_batch_number_changed
    end

    send_notification_email
  end

private

  def create_audit_activity_for_batch_number_changed
    metadata = activity_class.build_metadata(investigation_product)

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
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Case batch number updated"
      ).deliver_later
    end
  end

  def investigation
    investigation_product.investigation
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Case batch number was updated by #{user_name}."
  end
end
