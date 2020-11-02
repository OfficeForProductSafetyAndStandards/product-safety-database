class UpdateEmail
  include Interactor
  include EntitiesToNotify

  delegate :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file_action, :email_attachment_action, :email_file, :email_attachment, :email_file_id, :email_attachment_id, :attachment_description, to: :context

  delegate :investigation, to: :email

  def call
    context.fail!(error: "No email supplied") unless email.is_a?(Correspondence::Email)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    @previous_email_filename = email.email_file.try(:filename)
    @previous_email_attachment_filename = email.email_attachment.try(:filename)
    @previous_attachment_description = email.email_attachment.try(:metadata).to_h["description"]

    ActiveRecord::Base.transaction do
      email.attributes = {
        correspondent_name: correspondent_name,
        correspondence_date: correspondence_date,
        email_address: email_address,
        email_direction: email_direction,
        overview: overview,
        details: details,
        email_subject: email_subject
      }

      if email_file_action == "remove"
        email.email_file.detach
      elsif email_file_action == "keep"
        # Don't attach file if even it's present
      elsif email_file
        email.email_file.attach(email_file)
      elsif email_file_id
        email.email_file.attach(ActiveStorage::Blob.find_signed(email_file_id))
      end

      if email_attachment_action == "remove"
        email.email_attachment.detach
      elsif email_attachment_action == "keep"
        # Don't attach file if even it's present
      elsif email_attachment
        email.email_attachment.attach(email_attachment)
      elsif email_attachment_id
        email.email_attachment.attach(ActiveStorage::Blob.find_signed(email_attachment_id))
      end

      break if no_changes?

      email.save!

      if email.email_attachment.attached?
        update_attachment_description!
      end

      create_audit_activity
      send_notification_email
    end
  end

private

  def no_changes?
    !email.changed? &&
      (email_file_action == "keep" || (
        email_file_action.nil? && !email.email_file.attached?)) &&
      (email_attachment_action == "keep" || (email_attachment_action.nil? && !email.email_attachment.attached?)) &&
      (!email.email_attachment.attached? || (attachment_description == @previous_attachment_description.to_s))
  end

  def update_attachment_description!
    context.email.email_attachment.blob.metadata[:description] = attachment_description
    context.email.email_attachment.blob.save!
  end

  def create_audit_activity
    AuditActivity::Correspondence::EmailUpdated.create!(
      source: user_source,
      investigation: email.investigation,
      metadata: audit_activity_metadata,
      correspondence: email,
      title: nil,
      body: nil
    )
  end

  def user_source
    @user_source ||= UserSource.new(user: user)
  end

  def audit_activity_metadata
    AuditActivity::Correspondence::EmailUpdated.build_metadata(
      email: email,
      email_changed: (email_file.present? || email_file_action == "remove"),
      previous_email_filename: @previous_email_filename,
      email_attachment_changed: (email_attachment.present? || email_attachment_action == "remove"),
      previous_email_attachment_filename: @previous_email_attachment_filename,
      previous_attachment_description: @previous_attachment_description
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user_source.show(recipient)} edited an email on the #{investigation.case_type}.",
        "Email edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
