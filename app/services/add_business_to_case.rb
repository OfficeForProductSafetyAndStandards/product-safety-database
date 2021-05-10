class AddBusinessToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :business, :skip_email, to: :context

  def call
    context.fail!(error: "No business supplied")      unless business.is_a?(Business)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied")          unless user.is_a?(User)

    Business.transaction do
      Business.primary_location&.assign_attributes(name: "Registered office address", source: UserSource.new(user: user))

      business.investigation_businesses.each do |ib|
        ap ib
      end
      business.save!

      investigation.reload
      send_notification_email(create_audit_activity_for_business_added(business))
    end
  end

private

  def create_audit_activity_for_business_added(business)
    AuditActivity::Business::Add.create!(
      investigation: investigation,
      source: UserSource.new(user: user),
      business: business,
      metadata: AuditActivity::Business::Add
        .build_metadata(business, business.investigation_businesses.find_by!(investigation: investigation))
    )
  end

  def send_notification_email(activity)
    return if skip_email

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
