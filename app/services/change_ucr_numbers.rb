class ChangeUcrNumbers
  include Interactor
  include EntitiesToNotify

  delegate :investigation_product, :ucr_numbers, :user, to: :context

  def call
    context.fail!(error: "No investigation product supplied") unless investigation_product.is_a?(InvestigationProduct)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation_product.assign_attributes(ucr_numbers)

    ActiveRecord::Base.transaction do
      investigation_product.save!
      create_audit_activity_for_ucr_numbers_changed
    end
    context.changed = true

    send_notification_email
  end

private

  def create_audit_activity_for_ucr_numbers_changed
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
        "Case UCR numbers updated"
      ).deliver_later
    end
  end

  def investigation
    investigation_product.investigation
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Case UCR numbers was updated by #{user_name}."
  end
end