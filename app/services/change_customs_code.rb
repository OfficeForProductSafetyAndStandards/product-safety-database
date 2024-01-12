class ChangeCustomsCode
  include Interactor
  include EntitiesToNotify

  delegate :investigation_product, :customs_code, :user, to: :context

  def call
    context.fail!(error: "No investigation product supplied") unless investigation_product.is_a?(InvestigationProduct)
    context.fail!(error: "No customs code supplied") unless customs_code.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation_product.assign_attributes(customs_code:)

    return if investigation_product.changes.none?

    ActiveRecord::Base.transaction do
      investigation_product.save!
      create_audit_activity_for_customs_code_changed
    end
    context.changed = true

    send_notification_email unless context.silent
  end

private

  def create_audit_activity_for_customs_code_changed
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
    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Notification customs code updated"
      ).deliver_later
    end
  end

  def investigation
    investigation_product.investigation
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Notification customs code was updated by #{user_name}."
  end
end
