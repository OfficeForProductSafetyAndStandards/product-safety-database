class AddBusinessToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :relationship, :business, :skip_email, :online_marketplace, :other_marketplace_name, to: :context

  def call
    context.fail!(error: "No business supplied")      unless business.is_a?(Business)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied")          unless user.is_a?(User)

    create_online_marketplace if online_marketplace.blank? && other_marketplace_name.present?

    Business.transaction do
      business.primary_location&.assign_attributes(name: "Registered office address", added_by_user: user)
      investigation_business = business.investigation_businesses.build(investigation:, relationship:, online_marketplace:)
      business.save!

      send_notification_email(
        create_audit_activity_for_business_added(business, investigation_business)
      )
    end
  end

private

  def create_online_marketplace
    context.online_marketplace = OnlineMarketplace.create!(name: other_marketplace_name, approved_by_opss: false)
  end

  def create_audit_activity_for_business_added(business, investigation_business)
    AuditActivity::Business::Add.create!(
      investigation:,
      added_by_user: user,
      business:,
      metadata: AuditActivity::Business::Add.build_metadata(business, investigation_business)
    )
  end

  def send_notification_email(_activity)
    return unless investigation.sends_notifications?
    return if skip_email

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Business was added to the case by #{user.decorate.display_name(viewer: recipient)}.",
        "Business added"
      ).deliver_later
    end
  end
end
