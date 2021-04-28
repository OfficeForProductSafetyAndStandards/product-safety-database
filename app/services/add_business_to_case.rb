class AddBusinessToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :business, to: :context

  def call
    Business.transaction do
      business.primary_location.assign_attributes(name: "Registered office address", source: UserSource.new(user: user))
      business.save!
      send_notification_email(create_audit_activity_for_business_added(business))
    end
  end

private

  def create_audit_activity_for_business_added(business)
    AuditActivity::Business::Add.create!(
      investigation: investigation,
      business: business,
      metadata: AuditActivity::Business::Add.build_metadata(business)
    )
  end

  def send_notification_email(activity)
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Business was added to the #{investigation.case_type} by #{activity.source.show(recipient)}.",
        "Business added"
      ).deliver_later
    end
  end
end
