class UpdateDocument
  include Interactor
  include EntitiesToNotify

  delegate :file, :parent, :title, :description, :user, to: :context

  def call
    context.fail!(error: "Invalid parent object supplied") unless parent.respond_to?(:documents)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "File should be an instance of ActiveStorage::Blob") unless file.is_a?(ActiveStorage::Blob)

    ActiveRecord::Base.transaction do
      file.metadata.merge!(new_metadata)

      return if no_changes?

      file.metadata[:updated] = Time.zone.now
      file.save!

      create_audit_activity if investigation
    end

    send_notification_email if investigation
  end

private

  def no_changes?
    file.changes.none?
  end

  def old_title
    file.metadata[:title]
  end

  def old_description
    file.metadata[:description]
  end

  def new_metadata
    {
      title:,
      description:
    }
  end

  def audit_activity_metadata
    AuditActivity::Document::Update.build_metadata(file)
  end

  def create_audit_activity
    activity = AuditActivity::Document::Update.create!(
      metadata: audit_activity_metadata,
      added_by_user: user,
      investigation:
    )

    activity.attachment.attach(file)
  end

  def investigation
    parent if parent.is_a?(Investigation)
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(viewer = nil)
    "Document attached to the notification was updated by #{user&.decorate&.display_name(viewer:)}."
  end

  def email_subject
    "Notification updated"
  end
end
