class UpdateEmail
  include Interactor

  delegate :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, :attachment_description, to: :context

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

      if email_file
        email.email_file.attach(email_file)
      end

      if email_attachment
        email.email_attachment.attach(email_attachment)
      end

      break if no_changes?

      email.save!

      if email.email_attachment.attached? && attachment_description.present?
        update_attachment_description!
      end

      create_audit_activity
      send_notification_email
    end
  end

private

  def no_changes?
    !email.changed? && !email_file && (attachment_description == @previous_attachment_description.to_s)
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
      email_changed: email_file.present?,
      previous_email_filename: @previous_email_filename,
      email_attachment_changed: email_attachment.present?,
      previous_email_attachment_filename: @previous_email_attachment_filename,
      previous_attachment_description: @previous_attachment_description
    )
  end

  def send_notification_email
    entities_to_notify.each do |recipient|
      email_address = recipient.is_a?(Team) ? recipient.team_recipient_email : recipient.email

      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        email_address,
        "#{user_source.show(recipient)} edited an email on the #{investigation.case_type}.",
        "Email edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end

  def entities_to_notify
    return [] if user == investigation.owner_user
    return [investigation.owner_user, investigation.owner_team].compact if investigation.owner_team.email?

    investigation.owner_team.users.active.where.not(id: user.id)
  end
end
