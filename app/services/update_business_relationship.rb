class UpdateBusinessRelationship
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :investigation_business, :relationship, :relationship_other, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      investigation_business.assign_attributes(relationship: calculate_relationship)

      break if no_changes?

      investigation_business.save!

      create_audit_activity
      send_notification_email
    end
  end

private

  def calculate_relationship
    if relationship == "other"
      relationship_other
    else
      relationship
    end
  end

  def business
    investigation_business.business
  end

  def no_changes?
    !investigation_business.changed?
  end

  def create_audit_activity
    context.activity = AuditActivity::BusinessRelationship::Update.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      metadata: AuditActivity::BusinessRelationship::Update.build_metadata(investigation_business)
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Business relationship between #{business.trading_name} and the #{investigation.case_type} was changed to #{investigation_business.relationship} by #{user.name}.",
        "Business relationship updated"
      ).deliver_later
    end
  end
end
