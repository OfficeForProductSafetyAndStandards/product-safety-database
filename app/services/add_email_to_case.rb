class AddEmailToCase
  include Interactor

  delegate :investigation, :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, :attachment_description, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.email = investigation.emails.create!(
      correspondent_name: correspondent_name,
      correspondence_date: correspondence_date,
      email_address: email_address,
      email_direction: email_direction,
      overview: overview,
      details: details,
      email_subject: email_subject,
      email_file: email_file,
      email_attachment: email_attachment
    )

    if email.email_attachment.attached? && attachment_description.present?
      update_attachment_description!
    end

    # TODO: refactor into this class
    AuditActivity::Correspondence::AddEmail.from(email, investigation)
  end

private

  def update_attachment_description!
    context.email.email_attachment.blob.metadata[:description] = attachment_description
    context.email.email_attachment.blob.save!
  end
end
