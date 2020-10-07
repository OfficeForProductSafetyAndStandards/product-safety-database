class UpdateEmail
  include Interactor

  delegate :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, :attachment_description, to: :context

  def call
    context.fail!(error: "No email supplied") unless email.is_a?(Correspondence::Email)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    @previous_email_filename = email.email_file.try(:filename)

    ActiveRecord::Base.transaction do
      email.attributes = {
        correspondent_name: correspondent_name,
        correspondence_date: correspondence_date,
        email_address: email_address,
        email_direction: email_direction,
        overview: overview,
        details: details,
        email_subject: email_subject,
        email_file: email_file,
        email_attachment: email_attachment
      }

      break if no_changes?

      email.save!

      if email.email_attachment.attached? && attachment_description.present?
        update_attachment_description!
      end

      create_audit_activity
    end
  end

private

  def no_changes?
    !email.changed? && !email_file
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
      previous_email_filename: @previous_email_filename
    )
  end
end
